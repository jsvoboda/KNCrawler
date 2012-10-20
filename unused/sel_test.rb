require "selenium-webdriver"
require "rspec"
include RSpec::Expectations

describe "SelTest" do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "http://nahlizenidokn.cuzk.cz/"
    @driver.manage.timeouts.implicit_wait = 30
    @verification_errors = []
  end
  
  after(:each) do
    @driver.quit
    @verification_errors.should == []
  end
  
  it "test_sel" do
    @driver.get(@base_url + "/")
    @driver.find_element(:css, "img[alt=\"Informace o parcele\"]").click
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").clear
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_txtKU").send_keys "zelivsko"
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_vyberKU_btnKU").click
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_druhCislovani_0").click
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").clear
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_txtParcis").send_keys "44"
    @driver.find_element(:id, "ctl00_bodyPlaceHolder_btnVyhledat").click
    @driver.find_element(:link, "Sousední parcely").click
    @driver.find_element(:link, "st. 43").click
    @driver.find_element(:link, "107/2").click
  end
  
  def element_present?(how, what)
    @driver.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end
  
  def verify(&blk)
    yield
  rescue ExpectationNotMetError => ex
    @verification_errors << ex
  end
end
