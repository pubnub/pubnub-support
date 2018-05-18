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

$emails_sent = 0
$contacts_updated = 0

###########################################################################
#                         COMMAND LINE ARGUMENTS
###########################################################################

# https://ruby-doc.org/stdlib-2.4.1/libdoc/optparse/rdoc/OptionParser.html
$options = {}
# $options[:log] = false

OptionParser.new do |opts|
  opts.banner = "Usage: view_all_tickets.rb [options]"

  # opts.on("-n", "--company [String]", "Company Name, example -n Lorem Ipsum") do |opt|
  #   $options[:cname] = opt
  #   $company_name = opt
  # end

  opts.on("-i", "--company [Integer]", "Company ID, example -i 4567890123") do |opt|
    $options[:cid] = opt
    $company_id = opt
  end

  opts.on("-l", "--log [TrueClass]", "Enable Logging, example -l true") do |opt|
    $options[:log] = opt
  end

  # opts.on("-o", "--output [String]", "Output file, example -o weekly.txt") do |opt|
  #   $options[:output] = opt
  # end
end.parse!

puts
puts "OPTIONS"
# puts "company name  : #{$options[:cname]}"
puts "company id  : #{$options[:cid]}"
# puts "output file : #{$options[:output]}"
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

  begin
    response = site.get(:accept=>"application/json")
    # puts "URL response: #{response}"
    return JSON.parse(response)
  rescue => e
    e.response
    return nil
  end
end


def update_contact (contact)
  begin
    puts
    url =  "https://pubnub.freshdesk.com/api/v2/contacts/#{contact['id']}"
    puts "update contact url: #{url}"

    # if not active (account not activated) then update the email address
    # to trigger an activation email to be sent
    if (!contact['active'])
      email = contact['email']

      # set to bogus email
      email_data = JSON.generate({"email" => "bogus@example.com"})
      puts "setting to bogus email"
      site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")
      response = site.put(email_data, :content_type=>'application/json')

      # must sleep so that the two email updates don't trigger 
      # two activation emails to the customer - perhaps it could be .5 seconds or less?
      sleep 1

      # set back to original email
      puts "setting back to origina email: #{email}"
      email_data = JSON.generate({"email" => email})
      # email_data = JSON.generate({"email" => "cvconover+john@gmail.com"})
      site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")
      response = site.put(email_data, :content_type=>'application/json')

      $emails_sent = $emails_sent + 1
    end

    # update view_all_tickets attribute if needed
    if (contact['view_all_tickets'])
      puts "++++ Contact can already View All Tickets"
    else
      puts "---- Updating Contact to View All Tickets"

      jdata = JSON.generate({"view_all_tickets" => true})
      site = RestClient::Resource.new(url, "dHgVM1emGoTyr8zHmVNH")
      response = site.put(jdata, :content_type=>'application/json')

      # puts "URL response: #{response}"
      $contacts_updated = $contacts_updated + 1
      return JSON.parse(response)
    end
  rescue => e
    puts e
    return nil
  end
end


def get_contacts ()
  query = "(company_id:#{$company_id})"
  contacts = []
  more = true
  pg = 1
  total = 0

  while more do
    url = "https://pubnub.freshdesk.com/api/v2/search/contacts?query=\"#{query}\"&page=#{pg}"

    if ($options[:log])
      puts "contacts search url: #{url}"
    end

    response = invoke_request(url)
    results = response["results"]
    count = results.length

    if ($options[:log])
      puts "page results count: #{count}"
    end

    more = (count == 30)
    pg = pg + 1
    contacts = contacts + results
    total = total + count
  end

  puts "Total Contacts for #{$company_id}: #{total}"
  return contacts
end


get_contacts().each do |contact|
  puts
  puts "Contact: #{contact['name']}"
  update_contact(contact)
end

puts
puts "++++++++++++++++++++"
puts "Contacts updated      : #{$contacts_updated}"
puts "Activation emails sent: #{$emails_sent}"
