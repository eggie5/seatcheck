require 'rubygems'
require 'mechanize'
require 'ap'
require 'twitter'
require 'yaml'

class Course
  attr_accessor :name, :seats
  def initialize(name,seats)
    @name=name
    @seats=seats
  end
  def has_seats?
    (@seats[0..1]=="0/") ? false : true
  end
end

yaml = YAML.load_file("oauth.yaml")
Twitter.configure do |config|
  config.consumer_key = yaml["consumer_key"]
  config.consumer_secret = yaml["consumer_secret"]
  config.oauth_token = yaml["oauth_token"]
  config.oauth_token_secret = yaml["oauth_token_secret"]
end

agent = Mechanize.new

page = agent.get('http://sdsu.edu/')

page = agent.page.link_with(:text => 'WebPortal').click

form = page.forms.first

form.user_iden=yaml["redid"]
form.password=yaml["pass"]

page = agent.submit(form)

page = agent.page.link_with(:text => 'My Registration').click
page = agent.page.link_with(:text => 'Fall 2012').click
page = agent.page.link_with(:text => 'My Wish List').click

courses=[]
[4,5,6].each do |i|
  name=page.search("//tr/td/form/table/tr[#{i}]/td[2]/a").inner_text
  seats=page.search("//tr/td/form/table/tr[#{i}]/td[10]").inner_text
  c=Course.new(name, seats)
  courses.push c
end

c=Course.new("FAKE CLASS", "1/45")
courses.push c

courses.each do |course|
  if course.has_seats?
    m="#{course.name} has #{course.seats} seats"
    puts m
    Twitter.direct_message_create('eggie5', m)
    Twitter.direct_message_create('withlovecassee', m)
  end
end


