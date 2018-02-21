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


# VIPs
# Paid Support: Platinum (including VIP)
# Paid Support: Gold (including VIP)
# Paid Customers: Plan = "paying" AND (Support = Free OR Free++)
# Free Customers: Plan = Free

$query_unresolved = "(status:2 OR status:3 OR status:7 OR status:8 OR status:10 OR status:11 OR status:12)"
$query = Hash.new
# VIP
$query.store(1, {"name" => "VIP", "query" => "(cf_vip:true)"})
# Platinum Support
$query.store(2, {"name" => "Platinum Support", "query" => "(support_plan:'Platinum')"})
# Gold Support
$query.store(3, {"name" => "Gold Support", "query" => "(support_plan:'Gold')"})
# Paid Account, Free Support
$query.store(4, {"name" => "Paid Plan, Free Support", "query" => "((account_plan:'Standard' OR account_plan:'Pro Tx' OR account_plan:'Pro' OR account_plan:'Go' OR account_plan:'Global' OR account_plan:'Heroku') AND (support_plan:'Free' OR support_plan:'Free%2b%2b'))"})
# Paid Account, Free Support
$query.store(5, {"name" => "Free Plan, Free Support", "query" => "((account_plan:'Free') AND (support_plan:'Free' OR support_plan:'Free%2b%2b'))"})

###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: vips.rb [options]"

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


def invoke_request(url)
  site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")
  return JSON.parse(site.get(:accept=>"application/json"))
end


def get_tickets (query_category)
  tickets = []
  more = true
  pg = 1

  while more do
    url = "https://pubnub.freshdesk.com/api/v2/search/tickets?query=\"#{$query_unresolved} AND #{query_category}\"&page=#{pg}"

    if ($options[:log])
      puts "tickets url: #{url}"
    end

    response = invoke_request(url)
    results = response["results"]
    total = results.length
    puts "total page results: #{total}"

    more = (total == 30)
    pg = pg + 1
    tickets = tickets + results
  end

  # why was i doing this again?
  # response = invoke_request(url)
  return tickets
end


# def prompt(*args)
#     print(*args)
#     gets
# end
#
# name = prompt "Input name: "
$current_time = Time.now.to_i

def get_time_open(create_time)
  # puts
  # puts "create_time: #{create_time}"
  diff = $current_time - Time.parse(create_time).to_i
  # puts "diff: #{diff}"
  return diff
end

$query.each do |key, value|
  total_time = 0
  total_tickets = 0

  get_tickets(value['query']).each do |ticket|
    time_open = get_time_open(ticket['created_at'])
    total_time = total_time + time_open
    total_tickets = total_tickets + 1
  end # end tickets

  avg_open_seconds = total_time / total_tickets
  avg_open_minutes = (avg_open_seconds.to_f / 60).round(1)
  avg_open_hours = (avg_open_minutes / 60).round(1)
  avg_open_days = (avg_open_hours / 24).round(1)

  puts
  puts "#{key}) #{value['name']}"
  puts "-----------------------------------------"
  puts "Total Tickets:        #{total_tickets}"
  puts "Average Days Open:    #{avg_open_days}"
  puts "Average Hours Open:   #{avg_open_hours}"
  puts "Average Minutes Open: #{avg_open_minutes}"
  puts "Average Seconds Open: #{avg_open_seconds}"
end # query categories
