#!/usr/bin/ruby
require "xmlrpc/server"
require 'xmlrpc/client'
require 'rubygems'
require 'twitter'
require 'base64'
require 'tweetstream'

malcolm = 'malcy'
xmlrpc_url = 'REDACTED'
call_url = 'REDACTED'
consumer_key = 'REDACTED'  
consumer_secret = 'REDACTED'
oauth_token = 'REDACTED'
oauth_token_secret = 'REDACTED'

Twitter.configure do |config|
  config.consumer_key = consumer_key
  config.consumer_secret = consumer_secret
  config.oauth_token = oauth_token
  config.oauth_token_secret = oauth_token_secret
end
TweetStream.configure do |config|
  config.consumer_key = consumer_key
  config.consumer_secret = consumer_secret
  config.oauth_token = oauth_token
  config.oauth_token_secret = oauth_token_secret
  config.auth_method = :oauth
end

daemon = TweetStream::Daemon.new
daemon.userstream do |status|
  if status.text.match("^@#{malcolm}") then
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
    rescue Timeout::Error
      puts "Timeout Error, ignoring\n"
    end
  end
end
