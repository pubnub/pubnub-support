#create folder under a solution category
# encoding: UTF-8
require "rubygems"
require "rest-client"
require "json"
require "sequel"
require "redcarpet"
require "csv"
require 'nokogiri'
require 'optparse'
require 'date'
require 'json2csv'

# priorities = Hash.new
# priorities.store(1, "Low")
# priorities.store(2, "Medium")
# priorities.store(3, "High")
# priorities.store(4, "Urgent")

# cache resource lookups to minimize url calls
$agent_cache = Hash.new

###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: weekly.rb [options]"

  opts.on("-s", "--start [DATE]", "Start Date, example -s 2018-05-22") do |opt|
    $options[:start] = opt
  end

  opts.on("-e", "--end [Integer]", "End Date, example -e 2018-05-29") do |opt|
    $options[:end] = opt
  end

  opts.on("-l", "--log [TrueClass]", "Enable Logging, example -l true") do |opt|
    $options[:log] = opt
  end

  opts.on("-o", "--output [String]", "Output file, example -l weekly.txt") do |opt|
    $options[:output] = opt
  end
end.parse!

puts
puts "OPTIONS"
puts "start date  : #{$options[:start]}"
puts "end date    : #{$options[:end]}"
puts "output file : #{$options[:output]}"
puts "logging     : #{$options[:log]}"

if (!$options[:output].nil? && !$options[:output].empty?)
  $stdout.reopen($options[:output], "w")
  $stdout.sync = true
  $stderr.reopen($stdout)
end

###########################################################################
#                              TICKETS
###########################################################################

# puts '#################### Weekly Support Ticket Report ####################'

def invoke_request(url)
  site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")
  return JSON.parse(site.get(:accept=>"application/json"))
end

def get_agents ()
  # query = "(support_plan:'Platinum' OR support_plan:'Gold' OR support_plan:'Free%2B%2B' OR priority:'3' OR priority:'4') AND (created_at:>'#{$options[:start]}' AND created_at:<'#{$options[:end]}')"
  # url = "https://pubnub.freshdesk.com/api/v2/agents?query=\"#{query}\""
  url = "https://pubnub.freshdesk.com/api/v2/agents"

  if ($options[:log])
    puts "agent list url: #{url}"
  end

  response = invoke_request(url)
  # puts response
  # total = response["total"]
  # puts "Total Agents: #{total}"
  return response
  # ["results"]
end


def get_agent_detail (resource_id)
  if (!$agent_cache.has_key?(resource_id).nil?)
    return $agent_cache[resource_id]
  end

  resource_name = "agent?"

  if (!resource_id.nil?)
    url = "https://pubnub.freshdesk.com/api/v2/agents/#{resource_id}"

    if ($options[:log])
      puts "agent url: #{url}"
    end

    resource = invoke_request(url)

    if (!resource.nil? && !resource['name'].empty? && !resource['name'].empty?)
      resource_name = resource['contact']['name']
      $agent_cache.store(resource_id, resource_name)
    end
  end

  return resource_name
end

puts "name,created,updated,occasional,ticket_scope,groups,roles"

get_agents().each do |agent|
  # puts ticket
  # figure out what the company name is if company_id is not nil
  agent_detail = get_agent_detail(agent['id'])

  # old simple one liner ouput
  # puts "#{ticket['id']}\t#{statuses[ticket['status']]}\t#{priorities[ticket['priority']]}\t#{company['name']}\t#{ticket['custom_fields']['support_plan']}\t#{ticket['subject']}"

  created = Date.parse((agent['created_at']))
  updated = Date.parse((agent['updated_at']))
  occasional = agent['occasional']
  name = agent['contact']['name']
  ticket_scope = agent['ticket_scope']
  groups = agent['group_ids']
  roles = agent['role_ids']

  puts "#{name},#{created},#{updated},#{occasional},#{ticket_scope},#{groups},#{roles}"

  # puts "h3. #{company['name']}"
  # puts "-----"
  # # no csm
  # puts "h6. #{created} | #{agent_name} | #{ticket['custom_fields']['account_plan']} | #{ticket['custom_fields']['support_plan']} | #{priorities[ticket['priority']]} | #{ticket['custom_fields']['escalation']} | #{company['account_owner']} | #{company['csa']}"
  # # has csm
  # # puts "h6. #{created} | #{agent_name} | #{ticket['custom_fields']['account_plan']} | #{ticket['custom_fields']['support_plan']} | #{priorities[ticket['priority']]} | #{ticket['custom_fields']['escalation']} | #{company['account_owner']} | #{company['csm']} | #{company['csa']}"
  # puts "*[#{ticket['id']}|https://support.pubnub.com/helpdesk/tickets/#{ticket['id']}] - #{ticket['subject']}*"
  #
  # puts "* Customer "
  # puts "* "
end # end tickets
