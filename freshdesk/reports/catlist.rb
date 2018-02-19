#create folder under a solution category
# encoding: UTF-8
require "rubygems"
require "rest-client"
require "json"
require "sequel"
require "redcarpet"
require "csv"
require 'nokogiri'

########## FRESHDESK SETTINGS #########

domain = "pubnub"
web_url = "https://#{domain}.freshdesk.com/"
api_key = 'dHgVM1emGoTyr8zHmVNH'
pubnub_forum_id = 14000008295

###########################################################################
#                              CATEGORIES
###########################################################################

puts '#################### CATEGORIES ####################'

site = RestClient::Resource.new(web_url +"solution/categories.json",api_key)
response = site.get(:accept=>"application/json")
categories = JSON.parse(response.body)

categories.each do |category|
  category = category['category']

  ###########################################################################
  #                              FOLDERS
  ###########################################################################

    site = RestClient::Resource.new(web_url +"solution/categories/#{category['id']}.json",api_key)
    response = site.get(:accept=>"application/json")
    categories_with_folders = JSON.parse(response.body)
    puts categories_with_folders

    # categories_with_folders.each do |category_with_folders|
    #
    #   folders = category_with_folders[1]['folders']
    #
    #   folders.each do |folder|
    #
    #       puts "folder['name']"
    #
    #       ###########################################################################
    #       #                              ARTICLE
    #       ###########################################################################
    #
    #       site = RestClient::Resource.new(web_url +"/solution/categories/#{category['id']}/folders/#{folder['id']}.json",api_key)
    #       response = site.get(:accept=>"application/json")
    #       articles = JSON.parse(response.body)
    #
    #       puts '=======articles======='
    #
    #
    #       articles['folder']['articles'].each do |article|
    #
    #         puts article['title']
    #
    #         payload = {
    #            "name": "#{article['title']}",
    #            "auto": true,
    #            "contexts": [],
    #            "templates": [
    #               "#{article['title']}"
    #            ],
    #            "userSays": [
    #               {
    #                  "data": [
    #                     {
    #                        "text": "#{article['title']}"
    #                     }
    #                  ],
    #                  "isTemplate": false,
    #                  "count": 0
    #               }
    #            ],
    #            "responses": [
    #               {
    #                  "resetContexts": false,
    #                  "affectedContexts": [],
    #                  "parameters": [],
    #                  "speech": "#{Nokogiri::HTML(article['desc_un_html']).text.encode!('UTF-16', 'UTF-8')}"
    #               }
    #            ],
    #            "priority": 500000
    #         }
    #         req = RestClient.post("https://api.api.ai/v1/intents", payload.to_json, {Authorization: "Bearer 5843c5d283d34df09dae09234039c66e",content_type: "application/json; charset=utf-8"})
    #         sleep(10)
    #
    #       end
    #
    #   end
    # end # end folders
end # end categories
