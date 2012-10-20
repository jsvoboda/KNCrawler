# encoding: UTF-8

#TODO kodovani

require "selenium-webdriver"
require "set"
require "sqlite3"
require "pry"
# require "rspec"
# include RSpec::Expectations

#TODO is home province visited?

class Starter
    def initialize
        if ARGV.length == 0 then
            raise ArgumentError, "ERROR: no command line args"
        end

        kn_miners = []

        if ARGV.include? "-z" then
            kn_miners.push KNMiner.new :horakova_lhota
            # kn_miners.push KNMiner.new :zelivsko
        end
        if ARGV.include? "-h_l" then
            kn_miners.push KNMiner.new :horakova_lhota
            # t1 = Thread.new{KNMiner.new(:horakova_lhota).mine}
        end
        if ARGV.include? "-h_s" then
            kn_miners.push KNMiner.new :horni_smrzov
            # t2 = Thread.new{KNMiner.new(:horni_smrzov).mine}
        end

        kn_miners.each {|miner| miner.mine}
        # kn_miners.each {|miner| Thread.new{miner.mine}}
    end
end


class KNMiner
    attr_accessor :visited

    def initialize region
        case region
        when :zelivsko then
            @current_region = "Želivsko"
            @start_land_num = "st. 44"
        when :horakova_lhota then
            @current_region = "Horákova Lhota"
            @start_land_num = "91"
        when :horni_smrzov then
            @current_region = "Horní Smržov"
            @start_land_num = "10/5"
        end

        @current_table_name = region.to_s

        @driver = Selenium::WebDriver.for :firefox
        # @driver = Selenium::WebDriver.for(:firefox, :profile => "selenium")
        @driver.manage.timeouts.implicit_wait = 5

        @visited = Set.new

        @land_id_regex = /(?:st\. )?(\d*)\/?(\d*)?/ #extracts nums from land_num
        @neighbors_regex = /^(.*?)\s((st\.\s)?\d*(\/\d*)?)\sVlastníci >>/

        @land_num_regex = /^Parcelní číslo:\s(.*)$/
        @municipality_regex = /^Obec: (.*)$/
        @region_regex = /^Katastrální území: (.*)$/
        @lv_num_regex = /^Číslo LV: (.*)$/
        @area_regex = /^Výměra .*: (.*)$/
        @land_type_regex = /^Druh pozemku: (.*)$/
        @owner_regex = /Vlastnické právo\nJméno\/název Adresa Podíl\n(.*)Způsob ochrany nemovitosti/m
        @property_protection_regex = /Způsob ochrany nemovitosti\n(?:Název\n)?(.*)Seznam BPEJ/m
        @bpej_regex = /^BPEJ Výměra\n(.*)Omezení vlastnického práva/m

        @db = SQLite3::Database.new "Katastr.db"
        # @db.execute "DROP TABLE Zelivsko"
        # @db.execute "CREATE TABLE Zelivsko(land_num TEXT, owner TEXT)"

        begin
            @db.execute "DROP TABLE #{@current_table_name}"
            @db.execute "DROP TABLE #{@current_table_name}_bpej"
        rescue SQLite3::SQLException
        end
        @db.execute "CREATE VIRTUAL TABLE #{@current_table_name} USING fts3(land_num TEXT, "\
        "municipality TEXT, region TEXT, lv_num TEXT, area TEXT, owner TEXT, property_protection TEXT)"
        @db.execute "CREATE VIRTUAL TABLE #{@current_table_name}_bpej USING fts3(land_num TEXT, bpej TEXT, area TEXT)"
    end

    def mine
        if @current_region == "Horní Smržov" then
            mine_old
        else
            # go_to_start current_region land_num
            go_to_land(@start_land_num, @current_region)

            queue = visit_neighbors #visit home land and get first level neighbors

            while not queue.empty? do
                land_id = queue.shift
                go_to_land(land_id, @current_region)
                new_targets = visit_neighbors
                new_targets.each {|t| queue.push t}
            end
        end
    end

    def mine_old
        land_num_guess = 1
        # try_subs = false

        while true
            try_land(land_num_guess.to_s, @current_region)
            try_land("st. " + land_num_guess.to_s, @current_region)

            # go_to_land(land_num_guess.to_s + "/1", @current_region)

            # if text.match(@municipality_regex) then
            #     try_subs = true
            # end

            if land_num_guess == 78
                sub_num = 1
                while sub_num < 100
                    try_land(land_num_guess.to_s + "/" + sub_num.to_s, @current_region)
                    try_land("st. " + land_num_guess.to_s + "/" + sub_num.to_s, @current_region)

                    sub_num = sub_num.next
                end
            else
                # if try_subs then
                    sub_num = 1

                    while sub_num < 20
                        if not (try_land(land_num_guess.to_s + "/" + sub_num.to_s, @current_region) ||
                                try_land("st. " + land_num_guess.to_s + "/" + sub_num.to_s, @current_region)) then
                            break
                        end

                        sub_num = sub_num.next
                    end

                    # while true
                    #     go_to_land(land_num_guess.to_s + sub_num.to_s, @current_region)

                    #     text = @driver.find_element(:id, "content").text.encode('UTF-8')

                    #     if text.match(@municipality_regex) then
                    #         land_details = get_land_details
                    #         store_land_details land_details
                    #     else
                    #         break
                    #     end

                    #     sub_num = sub_num.next
                    # end
                # end
            end
            # try_subs = false
            land_num_guess = land_num_guess.next
        end
    end

    private 
    def try_land(land_num, region)
        go_to_land(land_num, region)

        text = @driver.find_element(:id, "content").text.encode('UTF-8')

        if text.match(@municipality_regex) then
            land_details = get_land_details
            store_land_details land_details
            return true
        end

        return false
    end

    private
    def get_land_details
        #find and parse the details
        # puts "@@@@@@@@"
        # puts @driver.find_element(:id, "content").text.encode('UTF-8')
        # puts "@@@@@@@@"
        text = @driver.find_element(:id, "content").text.encode('UTF-8')

        out = Hash.new

        m = text.match @land_num_regex
        visited.add m[1]
        out[:land_num] = m[1]

        m = text.match @municipality_regex
        out[:municipality] = m[1]

        m = text.match @region_regex
        out[:region] = m[1]

        m = text.match @lv_num_regex
        out[:lv_num] = m[1]

        m = text.match @area_regex
        out[:area] = m[1]

        m = text.match @owner_regex
        out[:owner] = m[1]

        m = text.match @property_protection_regex
        out[:property_protection] = m[1]

        m = text.match @bpej_regex
        if m then
            out[:bpej] = m[1]
        end

        out
    end

    private
    def store_land_details(hash)
        #store the parsed details in database
        @db.execute "INSERT INTO #{@current_table_name}(land_num, municipality, "\
        "region, lv_num, area, owner, property_protection) "\
        "VALUES ('#{hash[:land_num]}', '#{hash[:municipality]}', '#{hash[:region]}', "\
        "'#{hash[:lv_num]}', '#{hash[:area]}', '#{hash[:owner]}', '#{hash[:property_protection]}')"

        if hash[:bpej] then
            hash[:bpej].lines.each do |line|
                split_line = line.split
                @db.execute "INSERT INTO #{@current_table_name}_bpej(land_num, bpej, area) "\
                "VALUES ('#{hash[:land_num]}', '#{split_line[0]}', '#{split_line[1]}')"
            end
        end
    end

    # def get_neighbors_ids
    #     @driver.find_element(:link, "Sousední parcely").click
    #     text = @driver.find_element(:id, "content").text
    #     neighbors_ids = []

    #     text.lines.each do |line|
    #         m = line.match @neighbors_regex
    #         if m && m[1] == @currentArea && !visited.include?(m[2])
    #             queue.push(m[2])
    #         end
    #     end

    #     neighbors_ids
    # end

    private
    def visit_neighbors
        @driver.find_element(:link, "Sousední parcely").click
        text = @driver.find_element(:id, "content").text
        parrent_num = text.match(@land_num_regex)[1]
        queue = [] #used internally to visit immediate neighbors
        unvisited = [] #output of the method, used to mine the whole graph

        # puts ">>>>>>>"
        text.lines.each do |line|
            m = line.match @neighbors_regex
            if m && m[1] == @current_region && !visited.include?(m[2])
                queue.push(m[2])
            end
        end
        # puts queue
        # puts "======="

        queue.each do |id|
            @driver.find_element(:link, id).click
            land_details = get_land_details
            store_land_details land_details
            unvisited.push land_details[:land_num]

            #return to parrent
            @driver.find_element(:link, "Sousední parcely").click
            @driver.find_element(:link, parrent_num).click
            @driver.find_element(:link, "Sousední parcely").click
        end

        unvisited
    end


    private
    def go_to_land(land_num, region)
        @driver.manage.delete_all_cookies

        @driver.get("http://nahlizenidokn.cuzk.cz/VyberParcelu.aspx")
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").clear

        # if not @driver.find_elements(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").empty?
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").send_keys region
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_btnKU").click
        # end


        if land_num.start_with? "st." then
            @driver.find_element(:id, "ctl00_bodyPlaceHolder_druhCislovani_0").click
        end

        m = land_num.match @land_id_regex

        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").send_keys m[1]
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParpod").clear
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParpod").send_keys m[2]
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_btnVyhledat").click
    end

    # def go_to_start region
    #     #go to the starting land of the region
    #     @driver.manage.delete_all_cookies

    #     @driver.get("http://nahlizenidokn.cuzk.cz/")
    #     @driver.find_element(:css, "img[alt=\"Informace o parcele\"]").click
    #     @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").clear


    #     if region == "zelivsko"
    #         @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").send_keys "zelivsko"
    #         @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_btnKU").click
    #         @driver.find_element(:id, "ctl00_bodyPlaceHolder_druhCislovani_0").click
    #         @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").clear
    #         @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").send_keys "44"
    #         @driver.find_element(:id, "ctl00_bodyPlaceHolder_btnVyhledat").click
    #     end
    # end
end


starter = Starter.new

# kn_miner = KNMiner.new

# kn_miner.mine "zelivsko"

