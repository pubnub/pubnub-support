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

$tickets_updated = 0

$vips = Hash.new

###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: update_vip_tickets.rb [options]"

  # opts.on("-s", "--start [DATE]", "Start Date, example -s 2018-05-22") do |opt|
  #   $options[:start] = opt
  # end
  #
  # opts.on("-e", "--end [Integer]", "End Date, example -e 2018-05-29") do |opt|
  #   $options[:end] = opt
  # end

  opts.on("-l", "--log [TrueClass]", "Enable Logging, example -l true") do |opt|
    $options[:log] = opt
  end

  # opts.on("-o", "--output [String]", "Output file, example -o weekly.txt") do |opt|
  #   $options[:output] = opt
  # end
end.parse!

puts
puts "OPTIONS"
# puts "start date  : #{$options[:start]}"
# puts "end date    : #{$options[:end]}"
# puts "output file : #{$options[:output]}"
puts "logging     : #{$options[:log]}"

# if (!$options[:output].nil? && !$options[:output].empty?)
#   $stdout.reopen($options[:output], "w")
#   $stdout.sync = true
#   $stderr.reopen($stdout)
# end

###########################################################################
#                              TICKETS
###########################################################################

# puts '#################### Weekly Support Ticket Report ####################'

def invoke_request(url)
  site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")

  begin
    response = site.get(:accept=>"application/json")
    # puts "URL response: #{response}"
    return JSON.parse(response)
  rescue => e
    e.response
    return nil
  end
end


def get_tickets (resource_id)
  url = "https://pubnub.freshdesk.com/api/v2/tickets?company_id=#{resource_id}"

  if ($options[:log])
    puts "tickets url: #{url}"
  end

  response = invoke_request(url)

  # search tickets results
  # total = response["total"]
  # puts "_Total Tickets: #{total}_"
  # return response["results"]

  total = response.length
  puts "_Total Tickets: #{total}_"
  return response
end


def update_ticket (resource)
  begin
    # get ticket data (which has the tags)
    url = "https://pubnub.freshdesk.com/api/v2/tickets/#{resource['id']}"
    ticket = invoke_request(url)

    # jdata = {"custom_fields" => {"cf_vip" => true}, "tags" => ["VIP"]}
    tags = ticket['tags']
    puts tags
    tags.push('VIP')
    jdata = JSON.generate({"custom_fields" => {"cf_vip" => true}, "tags" => tags})
    # url =  "https://pubnub.freshdesk.com/api/v2/tickets/#{resource['id']}"
    # puts "update ticket url: #{url}"

    site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")
    response = site.put(jdata, :content_type=>'application/json')

    # puts "URL response: #{response}"
    $tickets_updated = $tickets_updated + 1
    return JSON.parse(response)
  rescue => e
    puts e
    return nil
  end
end


def process_tickets (companies)
  companies.each do |company|
    get_tickets(company['id']).each do |ticket|
      # puts
      # puts "TICKET: #{ticket['id']}"
      # puts "ticket data: #{ticket}"

      # figure out what the company name is if company_id is not nil
        puts "TICKET : #{ticket['id']} - #{ticket['subject']}"

        if (ticket['custom_fields']['cf_vip'])
          puts "++++ Ticket = VIP"
        else
          puts "---- Updating Ticket to VIP"
          update_ticket(ticket)
        end
    end # end get tickets

    puts
    puts "Total tickets updated: #{$tickets_updated}"
  end # end companies
end


def get_vip_companies ()
  pg = 1
  query = "(vip:true)"
  more = true
  companies = []

  while more do
    url = "https://pubnub.freshdesk.com/api/v2/search/companies?query=\"#{query}\"&page=#{pg}"

    if ($options[:log])
      puts "companies url: #{url}"
    end

    response = invoke_request(url)

    results = response["results"]
    more = (results.length == 30)
    pg = pg + 1
    companies = companies + results
  end

  return companies.sort_by{ |hsh| hsh["name"] }
end


def prompt(*args)
    print(*args)
    gets
end

def prompt(*args)
    print(*args)
    gets
end

# def main()
  i = 1
  puts "getting vips"
  get_vip_companies().each do |company|
    $vips.store(i, company)
    puts "#{i}) #{company['id']}, #{company['name']}"
    i = i +1
  end # end tickets

  companies = []
  selection = prompt "Input Company Numbers to process (2,3,34,...) or ALL for all VIPs: "
  selection = selection.delete(' ')

  puts "selection: #{selection}"

  if (selection == "ALL")
    puts "You selected ALL companies"
    companies = $vips
  else
    selection = selection.split(",")
    puts "You selected: #{selection}"

    selection.each do |index|
      companies.push($vips[index.to_i])
    end
  end

  process_tickets(companies)

# end
#
# main()
