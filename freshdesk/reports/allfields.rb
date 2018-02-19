#create folder under a solution category
# encoding: UTF-8
require "rubygems"
require "rest-client"
require "json"
require "sequel"
require "redcarpet"
require "csv"
require 'nokogiri'

########## FRESHDESK SETTINGS #########

domain = "pubnub"
web_url = "https://#{domain}.freshdesk.com/"
api_key = 'dHgVM1emGoTyr8zHmVNH'


###########################################################################
#                              Fields
###########################################################################

fields_query = RestClient::Resource.new(web_url + "/api/v2/ticket_fields", api_key)
fields_response = fields_query.get(:accept=>"application/json")
fields = JSON.parse(fields_response.body)
puts fields
fields.each do |field|
  # ticket = ticket['ticket']
  puts field
end # end tickets
