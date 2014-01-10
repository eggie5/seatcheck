require 'rubygems'
require 'mechanize'
require 'ap'
require 'twitter'
require 'yaml'
require 'logger'
$LOG = Logger.new(File.dirname(__FILE__)+"/seatcheck.log", 'monthly')

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

def log(m)
  $LOG.info(m)
  p m
end

yaml = YAML.load_file(File.dirname(__FILE__)+"/oauth.yaml")
twclient = Twitter::REST::Client.new do |config|
  config.consumer_key = yaml["consumer_key"]
  config.consumer_secret = yaml["consumer_secret"]
  config.oauth_token = yaml["oauth_token"]
  config.oauth_token_secret = yaml["oauth_token_secret"]
end

agent = Mechanize.new
# agent.log = Logger.new('mlog.txt')

#add this b/c sdsu's page returns text/plain so forece it html for mech
agent = Mechanize.new { |a|
  a.post_connect_hooks << lambda { |_,_,response,_|
    if response.content_type=="text/plain"
      response.content_type = 'text/html'
    end
  }
}
agent.follow_meta_refresh = true #follow location headers



page = agent.get('http://sdsu.edu/')
page = agent.page.link_with(:text => 'WebPortal').click
page = page.link_with(:text=>"Log In").click
form = page.forms.first
form.userName=yaml["redid"]
form.userPassword=yaml["pass"]
form["login"]="Sign In"
page = agent.submit(form)



page = page.link_with(:text => 'My Registration').click
page = page.link_with(:text => 'Spring 2014').click
page = page.link_with(:text => 'My Wish List').click


courses=[]
[2].each do |i|
  name=page.search("//tr/td/form/table/tr[#{i}]/td[2]/a").inner_text
  seats=page.search("//tr/td/form/table/tr[#{i}]/td[10]").inner_text
  c=Course.new(name, seats)
  courses.push c
end

courses.each do |course|
  if course.has_seats?
    m="#{Time.now.to_i} - #{course.name} has #{course.seats} seats"
    log m
    twclient.create_direct_message('eggie5', m)
    twclient.create_direct_message('withlovecassee', m)
  else
    log "no seats..."
  end
end
