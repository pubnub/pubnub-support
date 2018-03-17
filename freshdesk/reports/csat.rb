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


# VIPs
# Paid Support: Platinum (including VIP)
# Paid Support: Gold (including VIP)
# Paid Customers: Plan = "paying" AND (Support = Free OR Free++)
# Free Customers: Plan = Free



# contains all unresolved tickets returned by the query
# key = ticket_id, value = ticket record
$all_tickets = Hash.new


###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: csat.rb [options]"

  opts.on("-s", "--start [DATE]", "Start Date, example -s 2018-05-22") do |opt|
    $options[:start] = opt
  end

  opts.on("-e", "--end [Integer]", "End Date, example -e 2018-05-29") do |opt|
    $options[:end] = opt
  end

  opts.on("-l", "--log [TrueClass]", "Enable Logging, example -l true") do |opt|
    $options[:log] = opt
  end

  opts.on("-o", "--output [String]", "Output file, example -o csat.txt") do |opt|
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


def get_csats()
  url = "https://pubnub.freshdesk.com/api/v2/surveys/satisfaction_ratings?created_since=#{$created_since}"

  if ($options[:log])
    puts "tickets url: #{url}"
  end

  response = invoke_request(url)
  results = response["results"]
  total = results.length

  if ($options[:log])
    puts "total page results: #{total}"
  end

  return results
end


def main()
  get_unresolved_tickets()

end

main()
puts
