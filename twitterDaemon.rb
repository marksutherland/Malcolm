#!/usr/bin/ruby
require "xmlrpc/server"
require 'xmlrpc/client'
require 'rubygems'
require 'twitter'
require 'base64'

malcolm = 'malcy'
password = 'TOPSEKRIT'
xmlrpc_url = "http://some.stupid.domain:14159"
call_url = "http://some.stupid.domain:14160"
Twitter.configure do |config|
  config.consumer_key = ''  
  config.consumer_secret = ''
  config.oauth_token = ''
  config.oauth_token_secret = ''
end

current_time = Time.now
new_current_time = nil
failures = 0
nap_length = 190
snooze_length = 60

while(true) do
  begin
    Twitter.mentions(malcolm).each do |reply|
      if failures > 0 then
        print "Twitter is back up!\n"
        failures = 0
      end

      reply_time = reply.created_at

      if reply_time > current_time then
        reply.text.match("@#{malcolm} \(.*\)")
        message = $1
        user = reply.user.screen_name
        serialdata = Base64.encode64(user + " " + message)
        print "Querying: #{user}: #{message}\n"

        xmlrpc = XMLRPC::Client.new2(xmlrpc_url)
        result = xmlrpc.call("query",call_url,serialdata,message)

        twit_result = "@#{user} #{result}"
        print "Result: #{twit_result}\n"
        Twitter.update(twit_result[0..139])
        new_current_time = reply_time
      else
        if new_current_time then
          current_time = new_current_time
        end
        break
      end
    end
    sleep(nap_length)
  rescue Twitter::Error::Forbidden
    # This probably meant we tried to post the same status twice. Just ignore
    # it.
  rescue Timeout::Error
    print "Timeout Error, ignoring\n"
    sleep(nap_length)
  end
end
