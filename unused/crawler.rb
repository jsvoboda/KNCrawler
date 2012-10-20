require 'uri'
require 'net/http'

params = {'action' => 'ZobrazObjekt.aspx?typ=parcela&amp;id=3419319609'}
x = Net::HTTP.post_form(URI.parse('http://nahlizenidokn.cuzk.cz/VyberParcelu.aspx'), params)
puts x.body
gets