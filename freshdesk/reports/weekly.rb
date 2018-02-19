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

statuses = Hash.new
statuses.store(1, "New")
statuses.store(2, "Open")
statuses.store(3, "Pending")
statuses.store(4, "Resolved")
statuses.store(5, "Closed")
statuses.store(7, "Third Party")
statuses.store(8, "Engineering")
statuses.store(10, "Product Management")
statuses.store(11, "Corporate")
statuses.store(12, "Billing")
statuses.store(13, "Bug Bounty")
statuses.store(14, "Email Processing")

priorities = Hash.new
priorities.store(1, "Low")
priorities.store(2, "Medium")
priorities.store(3, "High")
priorities.store(4, "Urgent")

# cache resource lookups to minimize url calls
$company_cache = Hash.new
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

  opts.on("-o", "--output [String]", "Output file, example -o weekly.txt") do |opt|
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

def get_tickets ()
  query = "(support_plan:'Platinum' OR support_plan:'Gold' OR support_plan:'Free%2B%2B' OR priority:'3' OR priority:'4' OR cf_vip:true) AND (created_at:>'#{$options[:start]}' AND created_at:<'#{$options[:end]}')"
  url = "https://pubnub.freshdesk.com/api/v2/search/tickets?query=\"#{query}\""

  if ($options[:log])
    puts "tickets url: #{url}"
  end

  response = invoke_request(url)
  total = response["total"]
  puts "_Total Tickets: #{total}_"
  return response["results"]
end


def get_company_data (resource_id)
  if ($company_cache.has_key?(resource_id))
    return $company_cache[resource_id]
  end

  # resource_name = "Unknown"
  company_data = Hash.new
  company_data['name'] = "company?"
  company_data['csa'] = "csa?"
  company_data['csm'] = "csm?"
  company_data['owner'] = "owner?"

  if (!resource_id.nil?)
    url = "https://pubnub.freshdesk.com/api/v2/companies/#{resource_id}"

    if ($options[:log])
      puts "company url: #{url}"
    end

    resource = invoke_request(url)

    if ($options[:log])
      puts "company data: #{resource}"
    end

    if (!resource.nil? && !resource['name'].nil? && !resource['name'].empty?)
      company_data.store('name', resource['name'])
      cfields = resource['custom_fields']
      company_data.store('account_owner', (cfields['account_owner'].nil? || cfields['account_owner'].empty?) ? "owner?" : cfields['account_owner'])
      company_data.store('csm', (cfields['csm'].nil? || cfields['csm'].empty?) ? "csm?" : cfields['csm'])
      company_data.store('csa', (cfields['csa'].nil? || cfields['csa'].empty?) ? "csa?" : cfields['csa'])
      $company_cache.store(resource_id, company_data)
    end
  end

  return company_data
end


def get_agent_name (resource_id)
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

get_tickets().each do |ticket|
  # puts ticket
  # figure out what the company name is if company_id is not nil
  company = get_company_data(ticket['company_id'])

  # old simple one liner ouput
  # puts "#{ticket['id']}\t#{statuses[ticket['status']]}\t#{priorities[ticket['priority']]}\t#{company['name']}\t#{ticket['custom_fields']['support_plan']}\t#{ticket['subject']}"

  created = Date.parse((ticket['created_at']))
  agent_name = get_agent_name(ticket['agent'])

  if (ticket['custom_fields']['cf_vip'])
    puts "h3. #{company['name']} !Weekly Report^vip.png!"
  else
    puts "h3. #{company['name']}"
  end
  puts "-----"
  # no csm
  puts "h6. #{created} | #{agent_name} | #{ticket['custom_fields']['account_plan']} | #{ticket['custom_fields']['support_plan']} | #{priorities[ticket['priority']]} | #{ticket['custom_fields']['escalation']} | #{company['account_owner']} | #{company['csa']}"
  # has csm
  # puts "h6. #{created} | #{agent_name} | #{ticket['custom_fields']['account_plan']} | #{ticket['custom_fields']['support_plan']} | #{priorities[ticket['priority']]} | #{ticket['custom_fields']['escalation']} | #{company['account_owner']} | #{company['csm']} | #{company['csa']}"
  puts "*[#{ticket['id']}|https://support.pubnub.com/helpdesk/tickets/#{ticket['id']}] - #{ticket['subject']}*"

  puts "* Customer "
  puts
end # end tickets
