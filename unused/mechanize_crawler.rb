require 'rubygems'
require 'mechanize'

# agent = Mechanize.new
# agent.get('http://nahlizenidokn.cuzk.cz') do |page|
#   # Click the login link
#   vyber_parcelu = a.click(page.link_with(:text => "Vyhledat parcelu"))

#   vyber_parcelu.links.each {|link| puts link}

#   # Submit the login form
#   # my_page = vyber_parcelu.form_with(:action => 'ZobrazObjekt.aspx?typ=parcela&amp;id=3419319609') do |f|
#   #   # f.form_loginname  = ARGV[0]
#   #   # f.form_pw         = ARGV[1]
#   # end.click_button

#   # my_page.links.each do |link|
#   #   text = link.text.strip
#   #   next unless text.length > 0
#   #   puts text
#   # end
# end


agent = Mechanize.new
page = agent.get('http://nahlizenidokn.cuzk.cz/VyberParcelu.aspx')

form = page.form_with(:action => 'VyberParcelu.aspx')
form.field_with(:name => "ctl00$bodyPlaceHolder$vyberKU$btnZmenKU").value = "796298"
form.field_with(:name => "ctl00$bodyPlaceHolder$druhCislovani").checked = "checked" 
form.field_with(:name => "ctl00$bodyPlaceHolder$txtParcis").value = "44" 
page = form.click_button
pp page