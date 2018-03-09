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
$query.store(4, {"name" => "Paid Plan, Free Support", "query" => "((account_plan:'Standard' OR account_plan:'Pro Tx' OR account_plan:'Pro' OR account_plan:'Go' OR account_plan:'Global' OR account_plan:'Global' OR account_plan:'Heroku') AND (support_plan:'Free' OR support_plan:'Free%2b%2b'))"})
# Paid Account, Free Support
$query.store(5, {"name" => "Free Plan, Free Support", "query" => "((account_plan:'Free') AND (support_plan:'Free' OR support_plan:'Free%2b%2b'))"})


# contains all unresolved tickets returned by the query
# key = ticket_id, value = ticket record
$all_tickets = Hash.new

# these arrays just contain a ticket id which is the key to the
#   $all_tickets hash where the value is the ticket record
$vip = Array.new # tickets marked as VIP
$plat = Array.new # Platinum support tickets
$gold = Array.new # Gold support tickets
$paid = Array.new # Paid account, Free/Free++ support tickets
$free = Array.new # Free account, Free/Free++ support tickets
$new = Array.new # tickets create after options start value

# categories used to loop through the different ticket types above to produce stats report
$categories = Hash.new
$categories.store(1, {"name" => "VIP", "list" => $vip})
$categories.store(2, {"name" => "Platinum Support", "list" => $plat})
$categories.store(3, {"name" => "Gold Support", "list" => $gold})
$categories.store(4, {"name" => "Paid Plan, Free Support", "list" => $paid})
$categories.store(5, {"name" => "Free Plan, Free Support", "list" => $free})
$categories.store(6, {"name" => "New", "list" => $new})

###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: support_okr.rb [options]"

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


def is_new_ticket(created_at)
  return created_at >= $options[:start]
end

def categorize_tickets(tickets)
  tickets.each do |ticket|
    ticket_id = ticket['id']
    custom_fields = ticket['custom_fields']

    $all_tickets.store(ticket_id, ticket)

    if (is_new_ticket(ticket['created_at']))
      # puts "new ticket: #{ticket_id}"
      $new.push(ticket_id)
      ticket['_new'] = true
    end

    # VIP customer tickets
    if (custom_fields['cf_vip'])
      # puts "VIP ticket: #{ticket_id}"
      $vip.push(ticket_id)
    end

    # Platinum support tickets
    if (custom_fields['support_plan'] == 'Platinum')
      # puts "Platinum ticket: #{ticket_id}"
      $plat.push(ticket_id)

    # Gold support tickets
    elsif (custom_fields['support_plan'] == 'Gold')
      # puts "Gold ticket: #{ticket_id}"
      $gold.push(ticket_id)

    # Free account, Free support tickets
    elsif (custom_fields['account_plan'].nil? || custom_fields['account_plan'].empty? || custom_fields['account_plan'] == 'Free')
      # puts "Free/Free ticket: #{ticket['id']}"
      $free.push(ticket_id)

    # Paid account, Free support tickets
    else
      # puts "Paid/Free ticket: #{ticket_id}"
      $paid.push(ticket_id)
    end
  end # tickets.each
end


def get_unresolved_tickets ()
  tickets = []
  more = true
  pg = 1

  while more do
    url = "https://pubnub.freshdesk.com/api/v2/search/tickets?query=\"#{$query_unresolved}\"&page=#{pg}"

    if ($options[:log])
      puts "tickets url: #{url}"
    end

    response = invoke_request(url)
    results = response["results"]
    total = results.length

    if ($options[:log])
      puts "total page results: #{total}"
    end

    more = (total == 30)
    pg = pg + 1
    tickets = tickets + results
  end

  categorize_tickets(tickets)
end


def get_time_open(create_time)
  # puts
  # puts "create_time: #{create_time}"
  diff = $current_time - Time.parse(create_time).to_i
  # puts "diff: #{diff}"
  return diff
end

def main()
  get_unresolved_tickets()
  $current_time = Time.now.to_i

  $categories.each do |key, value|
    puts
    puts "*#{key}) #{value['name']}*"
    puts "----"


    total_time = 0
    total_tickets = 0
    total_new = 0
    total_esc3 = 0
    total_esc2 = 0

    value['list'].each do |ticket_id|
      ticket = $all_tickets[ticket_id]
      time_open = get_time_open(ticket['created_at'])
      total_time = total_time + time_open
      total_esc3 = total_esc3 + (ticket['custom_fields']['escalation'] == '3 - Engineering' ? 1 : 0)
      total_esc2 = total_esc2 + (ticket['custom_fields']['escalation'] == '2 - Research' ? 1 : 0)

      if (key != 6) # not the New tickets category
        total_new = total_new + (ticket['_new'] ? 1 : 0)
      end
    end # end tickets (value['list'].each)

    total_tickets = value['list'].length
    avg_open_seconds = total_time / total_tickets
    avg_open_minutes = (avg_open_seconds.to_f / 60)
    avg_open_hours = (avg_open_minutes / 60)
    avg_open_days = (avg_open_hours / 24).round(0)
    hours_left = (avg_open_hours % 24).round(0)

    if (total_tickets > 0)
      puts "Average Open Duration: #{avg_open_days}d #{hours_left}h"

      puts "Total Tickets:         #{total_tickets}"

      if (key != 6) # not the New tickets category
        puts "  New this week:       #{total_new}"
      end

      puts "  Engineering:         #{total_esc3}"
      puts "  Research:            #{total_esc2}"

      # puts "Average Hours Open:    #{avg_open_hours}"
      # puts "Average Minutes Open:  #{avg_open_minutes}"
      # puts "Average Seconds Open:  #{avg_open_seconds}"
    else # total_tickets > 0
      puts "No tickets found for this category."
    end # total_tickets > 0
  end # $categories.each
end

main()
puts
