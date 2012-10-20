require 'anemone'

Anemone.crawl("http://nahlizenidokn.cuzk.cz/VyberParcelu.aspx") do |anemone|
  anemone.on_every_page do |page|
      puts page.url
  end
end
gets