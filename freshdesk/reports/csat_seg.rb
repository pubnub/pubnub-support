require "rubygems"
require "rest-client"
require "json"
require "sequel"
require "redcarpet"
require "csv"
require 'nokogiri'
require 'optparse'
require 'date'


$csat_tot = 0
$csats = Array.new

$csat_seg = Array.new(5)
$csat_seg[0] = [0,0]
$csat_seg[1] = [0,0]
$csat_seg[2] = [0,0]
$csat_seg[3] = [0,0]
$csat_seg[4] = [0,0]

# $csat_seg = Hash.new(5)
# $csat_seg.store('vip', Array.new(2))
# $csat_seg.store('plat', Array.new(2))
# $csat_seg.store('gold', Array.new(2))
# $csat_seg.store('paid', Array.new(2))
# $csat_seg.store('free', Array.new(2))

# categories used to loop through the different ticket types above to produce stats report
$segments = Hash.new
$segments.store(0, {"name" => "VIP", "list" => $csat_seg[0]})
$segments.store(1, {"name" => "Platinum", "list" => $csat_seg[1]})
$segments.store(2, {"name" => "Gold", "list" => $csat_seg[2]})
$segments.store(3, {"name" => "Paid / Free", "list" => $csat_seg[3]})
$segments.store(4, {"name" => "Free / Free", "list" => $csat_seg[4]})

###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: csat_seg.rb [options]"

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


def in_range(created_at)
  return created_at <= $options[:end]
end

def categorize_csats()
  $csats.each do |csat|
    if (in_range(csat['created_at']))
      $csat_tot = $csat_tot + 1
      ticket_id = csat['ticket_id']
      rating = csat['ratings']['default_question'] > 0 ? 0 : 1

      url = "https://pubnub.freshdesk.com/api/v2/tickets/#{ticket_id}"

      if ($options[:log])
        puts "ticket #{ticket_id} url: #{url}"
      end

      ticket = invoke_request(url)
      custom_fields = ticket['custom_fields']
      seg = 0

      # VIP customer tickets
      if (custom_fields['cf_vip'])
        seg = 0
      end

      # Platinum support tickets
      if (custom_fields['support_plan'] == 'Platinum')
        seg = 1
      end

      # Gold support tickets
      if (custom_fields['support_plan'] == 'Gold')
        seg = 2
      end

      if ((!custom_fields['account_plan'].nil? && !custom_fields['account_plan'].empty? && custom_fields['account_plan'] != 'Free') && (custom_fields['support_plan'] == 'Free' || custom_fields['support_plan'] == 'Free++'))
        seg = 3
      end

      # Free account, Free support tickets
      if ((custom_fields['account_plan'].nil? || custom_fields['account_plan'].empty? || custom_fields['account_plan'] == 'Free') && (custom_fields['support_plan'] == 'Free' || custom_fields['support_plan'] == 'Free++'))
        seg = 4
      end

      $csat_seg[seg][rating] = $csat_seg[seg][rating] + 1
    end
  end # tickets.each
end


def get_csats ()
  url = "https://pubnub.freshdesk.com/api/v2/surveys/satisfaction_ratings?created_since=#{$options[:start]}T23:59:59Z"

  if ($options[:log])
    puts "csat url: #{url}"
  end

  $csats = invoke_request(url)
  total = $csats.length
  puts "Total CSATs: #{total}"

  categorize_csats()
end


def get_time_open(create_time)
  # puts
  # puts "create_time: #{create_time}"
  diff = $current_time - Time.parse(create_time).to_i
  # puts "diff: #{diff}"
  return diff
end

def main()
  get_csats()
  $current_time = Time.now.to_i
  puts "csat_seg: #{$csat_seg}"

  puts
  puts "Total CSATs: #{$csat_tot}"
  puts "||Segment||Positive||Negative"
  $segments.each do |key, value|
    # puts "*#{key}) #{value['name']}*"
    # puts "----"
    seg_tot = value['list'][0] + value['list'][1]
    seg0_pct = 0
    seg1_pct = 0

    if (seg_tot > 0)
      seg0_pct = (value['list'][0].fdiv(seg_tot) * 100).round()
      seg1_pct = (value['list'][1].fdiv(seg_tot) * 100).round()
    end

    seg0_csat = seg_tot == 0 ? "0" : "#{seg0_pct}% (#{value['list'][0]})"
    seg1_csat = seg_tot == 0 ? "0" : "#{seg1_pct}% (#{value['list'][1]})"

    puts "|*#{value['name']}*|#{seg0_csat}|#{seg1_csat}"
  end # $categories.each
end

main()
puts
