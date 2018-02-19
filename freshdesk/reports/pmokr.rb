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

cur_date = Time.new
year = cur_date.year.to_s
month = cur_date.month.to_s.rjust(2, '0')
log = false

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: pmokr.rb [options]"

  opts.on("-m", "--month [Integer]", "Month, example 14") do |o|
    options[:month] = o
  end

  opts.on("-y", "--year [Integer]", "Year, example 2018") do |o|
    options[:year] = o
  end

  # opts.on("-l", "--log [FalseClass]", "Enable Logging, example -l true") do |opt|
  #   $options[:log] = opt
  # end
end.parse!

if (options[:year].nil? || options[:year].empty?)
  options[:year] = year
end

if (options[:month].nil? || options[:month].empty?)
  options[:month] = month
end

# if (options[:log].nil? || options[:log].empty?)
#   options[:log] = log
# end

puts
puts "OPTIONS"
puts "======="
puts "year    : #{options[:year]}"
puts "month   : #{options[:month]}"
# puts "logging : #{options[:log]}"

########## FRESHDESK SETTINGS #########

$statuses = ["New", "Open", "Pending", "Resolved", "Closed"]
$priorities = ["Low", "Medium", "High", "Urgent"]

def get_status (code)
  return $statuses[code]
end

def get_priority (code)
  return $priorities[code]
end

def get_url (start_date, end_date)
  query = "(link:'admin.pubnub.com') AND (created_at:>'#{start_date}' AND created_at:<'#{end_date}')"
  url = "https://pubnub.freshdesk.com/api/v2/search/tickets?query=\"#{query}\""
  # puts "url: #{url}"
  return url
end


###########################################################################
#                              TICKETS
###########################################################################

puts
puts "RESULTS"
puts "======="
# date = Time.new
# #set 'date' equal to the current date/time.
# date = date.day.to_s + "/" + date.month.to_s + "/" + date.year.to_s

date = (options[:month] == month && options[:year] == year) ? cur_date.day : 31
sdate = 1
edate = 7
total = 0
week = 1

while edate <= date
  start_date = "#{options[:year]}-#{options[:month]}-#{sdate.to_s.rjust(2, '0')}"
  end_date = "#{options[:year]}-#{options[:month]}-#{edate.to_s.rjust(2, '0')}"

  site = RestClient::Resource.new(get_url(start_date, end_date), "dHgVM1emGoTyr8zHmVNH")
  response = JSON.parse(site.get(:accept=>"application/json"))
  total += response["total"]
  puts "Week #{week}: #{start_date} to #{end_date}: #{response["total"]}"

  sdate += 7
  edate += 7
  week += 1
end

puts "--------------------------------------"
puts "Total : #{year}-#{options[:month]}-01 to #{end_date}: #{total}"
puts
