# encoding: UTF-8

#TODO kodovani

require "selenium-webdriver"
require "set"
require "sqlite3"
# require "rspec"
# include RSpec::Expectations

class KNMiner
    attr_accessor :visited

    def initialize
        @currentArea = "Želivsko"

        @driver = Selenium::WebDriver.for :firefox
        @driver.manage.timeouts.implicit_wait = 0

        @visited = Set.new
        # @land_num_regex = /Parcelní číslo: st. (\d*(\/\d*)?)/
        @land_num_regex = /^Parcelní číslo:\s(.*)$/
        @neighbors_regex = /^(.*?)\s((st\.\s)?\d*(\/\d*)?)\sVlastníci >>/
        # @land_num_regex = /Parcelní číslo: (.*)\n/
        @owner_regex = /Vlastnické právo\nJméno\/název Adresa Podíl\n(.*)Způsob ochrany nemovitosti/m
    

        @db = SQLite3::Database.new "Katastr.db"
        @db.execute "DROP TABLE Zelivsko"
        # @db.execute "CREATE TABLE Zelivsko(land_num TEXT, owner TEXT)"
        @db.execute "CREATE VIRTUAL TABLE Zelivsko USING fts3(land_num TEXT, owner TEXT)"
    end

    def get_land_details
        #find and parse the details
        puts "@@@@@@@@"
        puts @driver.find_element(:id, "content").text.encode('UTF-8')
        puts "@@@@@@@@"

        text = @driver.find_element(:id, "content").text.encode('UTF-8')

        out = Hash.new
        
        m = text.match @land_num_regex
        visited.add m[1]
        out[:land_num] = m[1]

        m = text.match @owner_regex
        out[:owner] = m[1]

        out
    end

    def store_land_details(hash)
        #store the parsed details in database
        @db.execute "INSERT INTO Zelivsko(land_num, owner) "\
        "VALUES ('#{hash[:land_num]}', '#{hash[:owner]}')"
    end

    def get_neighbors_ids
        @driver.find_element(:link, "Sousední parcely").click
        text = @driver.find_element(:id, "content").text
        neighbors_ids = []

        text.lines.each do |line|
            m = line.match @neighbors_regex
            if m && m[1] == @currentArea && !visited.include?(m[2])
                queue.push(m[2])
            end
        end
        
        neighbors_ids
    end

    def visit_neighbors #TODO use get_neighbors_ids
        @driver.find_element(:link, "Sousední parcely").click
        text = @driver.find_element(:id, "content").text
        parrent_num = text.match(@land_num_regex)[1]
        queue = []

        puts ">>>>>>>"
        text.lines.each do |line|
            m = line.match @neighbors_regex
            if m && m[1] == @currentArea && !visited.include?(m[2])
                queue.push(m[2])
            end
        ends
        puts queue
        puts "======="

        queue.each do |id|
            @driver.find_element(:link, id).click
            store_land_details(get_land_details)

            #return to parrent
            @driver.find_element(:link, "Sousední parcely").click
            @driver.find_element(:link, parrent_num).click
            @driver.find_element(:link, "Sousední parcely").click
        end

        # rs = @db.execute  "SELECT * FROM Zelivsko WHERE owner MATCH 'Jaromír'" 

        # puts "$$$"
        # rs.each do |row|
        #     puts row
        # end
        # puts "$$$"
    end

    def traverse
        queue = get_neighbors_ids

    end

    def go_to_start
       #get to home land   
        front_page = "http://nahlizenidokn.cuzk.cz/"
        @driver.get(front_page + "/")
        @driver.find_element(:css, "img[alt=\"Informace o parcele\"]").click
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").clear
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").send_keys "zelivsko"
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_btnKU").click
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_druhCislovani_0").click
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").clear
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").send_keys "44"
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_btnVyhledat").click 
        ####
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").send_keys "107"
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParpod").clear
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParpod").send_keys "3"
        @driver.find_element(:id, "ctl00_bodyPlaceHolder_btnVyhledat").click
    end
end




# puts @driver.find_element(:id, "content").text

# puts "---------"
# puts @driver.find_element(:id, "content").text.encode('UTF-8')
# puts "---------"
# puts details = kn_miner.get_land_details(@driver.find_element(:id, "content").text.encode('UTF-8'))
# puts "červený žlutý, ěščřžýáíé"
# puts "---------"

kn_miner = KNMiner.new

kn_miner.go_to_start

kn_miner.store_land_details (kn_miner.get_land_details)
kn_miner.visit_neighbors




###################################################################################

# # encoding: UTF-8

# #TODO kodovani

# require "selenium-webdriver"
# require "set"
# require "sqlite3"
# # require "rspec"
# # include RSpec::Expectations

# class KNMiner
#     attr_accessor :visited

#     def initialize
#         @visited = Set.new
#         # @land_num_regex = /Parcelní číslo: st. (\d*(\/\d*)?)/
#         @land_num_regex = /Parcelní číslo: (.*)\n/
#         @owner_regex = /Vlastnické právo\nJméno\/název Adresa Podíl\n(.*)Způsob ochrany nemovitosti/m
    
#         @db = SQLite3::Database.new "Katastr.db"
#         @db.execute "DROP TABLE Zelivsko"
#         # @db.execute "CREATE TABLE Zelivsko(land_num TEXT, owner TEXT)"
#         @db.execute "CREATE VIRTUAL TABLE Zelivsko USING fts3(land_num TEXT, owner TEXT)"
#         puts "@@@"
#         puts @db.encoding
#     end

#     def get_land_details(text)
#         #parse the details
#         out = Hash.new
        
#         m = text.match @land_num_regex
#         visited.add m[1]
#         out[:land_num] = m[1]

#         m = text.match @owner_regex
#         out[:owner] = m[1]

#         out
#     end

#     def store_land_details(hash)
#         #store the parsed details in database
#         @db.execute "INSERT INTO Zelivsko(land_num, owner) "\
#         "VALUES ('#{hash[:land_num]}', '#{hash[:owner]}')"
#         @db.execute "INSERT INTO Zelivsko(land_num, owner) VALUES ('červený žlutý', 'ěščřžýáíé')"

#         rs = @db.execute  "SELECT * FROM Zelivsko WHERE owner MATCH 'Jaromír'" 

#         puts "$$$"
#         rs.each do |row|
#             puts row.join "\s"
#         end
#         puts "$$$"
#     end

#     def visit_neighbors
#         @driver.find_element(:link, "Sousední parcely").click
#         puts @driver.find_element(:id, "content").text
#     end
# end




# @driver = Selenium::WebDriver.for :firefox
# @driver.manage.timeouts.implicit_wait = 30
# kn_miner = KNMiner.new

# #get to home land   
# front_page = "http://nahlizenidokn.cuzk.cz/"
# @driver.get(front_page + "/")
# @driver.find_element(:css, "img[alt=\"Informace o parcele\"]").click
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").clear
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").send_keys "zelivsko"
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_btnKU").click
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_druhCislovani_0").click
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").clear
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").send_keys "44"
# @driver.find_element(:id, "ctl00_bodyPlaceHolder_btnVyhledat").click

# # puts @driver.find_element(:id, "content").text

# puts "---------"
# puts @driver.find_element(:id, "content").text.encode('UTF-8')
# puts "---------"
# puts details = kn_miner.get_land_details(@driver.find_element(:id, "content").text.encode('UTF-8'))
# puts "červený žlutý, ěščřžýáíé"
# puts "---------"

# kn_miner.store_land_details details

# kn_miner.visit_neighbors


# # @driver.navigate.back
# # @driver.switch_to.alert.accept
# # driver.navigate.to("http://nahlizenidokn.cuzk.cz//VyberParcelu.aspx")

# # html = @driver.find_element(:id, "content").text
# # puts html
