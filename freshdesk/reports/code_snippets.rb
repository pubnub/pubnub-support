def get_company_id ()
  if ($company_cache.has_key?($company_name))
    return $company_cache[$company_name]['id']
  end

  # resource_name = "Unknown"
  company_data = Hash.new
  company_data['id'] = nil

  query = "(name:'#{$company_name}')"
  # query = "(domain:'#{$company_name}')"
  url = "https://pubnub.freshdesk.com/api/v2/search/companies?query=\"#{query}\""

  if ($options[:log])
    puts "company search url: #{url}"
  end

  response = invoke_request(url)

  if ($options[:log])
    puts "company data: #{response}"
  end

  company_id = response['results']['id']

  if (!company.nil? && !company_id.nil? && !company_id.empty?)
    company_data.store('id', company_id)
    $company_cache.store($company_name, company_id)
  end

  return company_id
end



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
