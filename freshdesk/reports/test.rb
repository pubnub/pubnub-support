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

$statuses = ["New", "Open", "Pending", "Resolved", "Closed"]
$priorities = ["Low", "Medium", "High", "Urgent"]

def get_status (code)
  return $statuses[code]
end

def get_priority (code)
  return $priorities[code]
end


###########################################################################
#                              TICKETS
###########################################################################

fields_query = RestClient::Resource.new(web_url + "/api/v2/ticket_fields", api_key)
fields_response = fields_query.get(:accept=>"application/json")
fields = JSON.parse(fields_response.body)
puts fields
fields.each do |field|
  # ticket = ticket['ticket']
  puts field

end # end tickets

puts '#################### Weekly Support Ticket Report ####################'

site = RestClient::Resource.new(web_url + "/api/v2/tickets", api_key)
# /api/v2/search/tickets?query=[query]
# "(type:'Question' OR type:'Problem') AND (due_by:>'2017-10-01' AND due_by:<'2017-10-07')"
# curl -v -u user@yourcompany.com:test -X GET 'https://domain.freshdesk.com/api/v2/search/tickets?query="(type:%27Question%27%20OR%20type:%27Problem%27)%20AND%20(due_by:>%272017-10-01%27%20AND%20due_by:<%272017-10-07%27)"'

response = site.get(:accept=>"application/json")
tickets = JSON.parse(response.body)

tickets.each do |ticket|
  # ticket = ticket['ticket']
  puts "#{get_priority(ticket['priority'])} #{ticket['id']}  #{ticket['subject']} #{get_status(ticket['status'])}"

end # end tickets
