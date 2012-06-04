#!/usr/bin/ruby
require "xmlrpc/server"
require 'xmlrpc/client'
require 'rubygems'
require 'twitter'
require 'base64'
require 'tweetstream'

malcolm = 'malcy'
password = 'TOPSEKRIT'
xmlrpc_url = "http://some.stupid.domain"
call_url = "http://some.stupid.domain"

puts "configuring twitter"
Twitter.configure do |config|
  config.consumer_key = ''  
  config.consumer_secret = ''
  config.oauth_token = ''
  config.oauth_token_secret = ''
end
puts "configuring tweetstream"
TweetStream.configure do |config|
  config.consumer_key = ''  
  config.consumer_secret = ''
  config.oauth_token = ''
  config.oauth_token_secret = ''
  config.auth_method = :oauth
end

puts "Starting daemon"
daemon = TweetStream::Daemon.new
daemon.userstream do |status|
  puts "got status"
  if status.text.match("^@#{malcolm}") then
    puts "matched reply"
    status.text.match("@#{malcolm} \(.*\)")
    message = $1
    user = status.user.screen_name
    serialdata = Base64.encode64(user + " " + message)
    puts "Querying: #{user}: #{message}\n"

    xmlrpc = XMLRPC::Client.new2(xmlrpc_url)
    result = xmlrpc.call("query",call_url,serialdata,message)

    begin
      twit_result = "@#{user} #{result}"
      puts "Result: #{twit_result}\n"
      Twitter.update(twit_result[0..139])
    rescue Twitter::Error::Forbidden
      # This probably meant we tried to post the same status twice. Just ignore
      # it.
      sleep(nap_length)
    rescue Timeout::Error
      puts "Timeout Error, ignoring\n"
      sleep(nap_length)
    end
  else
    puts "No match!\n"
  end
end
