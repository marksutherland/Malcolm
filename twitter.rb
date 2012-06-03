#!/usr/bin/ruby
require "xmlrpc/server"
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'

serv = XMLRPC::CGIServer.new

def get_tweet(malcolms_url, cbd, message)
  source = "http://twitter.com/statuses/user_timeline/" + message + ".rss?count=1"
  content = ""
  result = ""
  if message.match('\s') then
    result= "I'm sorry, but I can't let you do that, Dave"
  else
    begin
      open(source) { |s| content = s.read }
      rss = RSS::Parser.parse(content, false)
      result = rss.items[0].description
      result.sub!(/[^:]*: /, '')
    rescue OpenURI::HTTPError
      result = message + " is not cool enough for twitter"
    end
  end
  result
end

serv.add_handler("query") do |malcolms_url, some_crazy_random_string, message|
  get_tweet(malcolms_url, some_crazy_random_string, message)
end
  
serv.add_handler("spam") do |malcolms_url, some_crazy_random_string, message|
  get_tweet(malcolms_url, some_crazy_random_string, message)
end
  
serv.serve
