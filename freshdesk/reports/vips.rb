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

# cache resource lookups to minimize url calls
$company_cache = Hash.new

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

def get_vip_companies ()
  query = "(vip:true)"
  url = "https://pubnub.freshdesk.com/api/v2/search/companies?query=\"#{query}\""

  if ($options[:log])
    puts "companies url: #{url}"
  end

  response = invoke_request(url)
  total = response["total"]
  puts "_Total Companies: #{total}_"
  return response["results"]
end



def prompt(*args)
    print(*args)
    gets
end

get_vip_companies().each do |company|
  puts "#{i}) vips.store(#{company['id']}, \"#{company['name']}\")"
end # end tickets

def prompt(*args)
    print(*args)
    gets
end

name = prompt "Input name: "
