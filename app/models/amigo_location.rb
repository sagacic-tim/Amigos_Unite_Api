require 'bigdecimal'
require "smartystreets_ruby_sdk/client_builder"
require "smartystreets_ruby_sdk/static_credentials"
require "smartystreets_ruby_sdk/us_street/lookup"

class AmigoLocation < ApplicationRecord
  belongs_to :amigo
  before_save :validate_address_with_smartystreets

  def validate_address_with_smartystreets
    raw_address = "#{self.street_number} #{self.street_name} #{self.street_suffix} #{self.city}, #{self.state_abbreviation} #{self.postal_code}"
    # Call SmartyStreets API to validate the address
    puts "Validating address: #{raw_address}"
    puts Rails.application.credentials.dig(:smarty_streets, :auth_id)
    puts Rails.application.credentials.dig(:smarty_streets, :auth_token)
    app_auth_id = Rails.application.credentials.dig(:smarty_streets, :auth_id)
    app_auth_token = Rails.application.credentials.dig(:smarty_streets, :auth_token)
    puts "Auth ID: #{app_auth_id}, Auth Token: #{app_auth_token}"
    credentials = SmartyStreets::StaticCredentials.new(app_auth_id, app_auth_token)
    client = SmartyStreets::ClientBuilder.new(credentials).build_us_street_api_client
    lookup = SmartyStreets::USStreet::Lookup.new(raw_address) # Pass the address string as an argument
    lookup.match = :strict # Indicates an exact address match.

    begin
      client.send_lookup(lookup)
      puts "SmartyStreets API call made successfully."
    rescue SmartyStreets::SmartyError => err
      puts "SmartyStreets API call failed with error: #{err}"
      errors.add(:base, "Address validation failed with error: #{err}")
      throw(:abort) # Halts the callback chain and does not save the record
    end
    
    result = lookup.result

    if result.empty?
      puts 'No valid address candidates found by SmartyStreets.'
      errors.add(:base, 'No valid address candidates found.')
      throw(:abort) # Halts the callback chain and does not save the record
    else
      puts "Found address candidates: #{result.inspect}"
    end
    
    first_candidate = result[0]
    puts "Using address candidate: #{first_candidate.inspect}"

    self.address = "#{first_candidate.components.primary_number} #{first_candidate.components.street_predirection} #{first_candidate.components.street_name} #{first_candidate.components.street_suffix} #{first_candidate.components.street_postdirection} #{first_candidate.components.secondary_number} #{first_candidate.components.city_name}, #{first_candidate.components.state_abbreviation} US #{first_candidate.components.zipcode}-#{first_candidate.components.plus4_code}"
    self.address_type = first_candidate.metadata.rdi
    self.building = first_candidate.components.extra_secondary_number
    self.street_number = first_candidate.components.primary_number
    self.street_predirection = first_candidate.components.street_predirection
    self.street_name = first_candidate.components.street_name
    self.street_postdirection = first_candidate.components.street_postdirection
    self.street_suffix = first_candidate.components.street_suffix
    self.apartment_suite_number = first_candidate.components.secondary_number
    self.city = first_candidate.components.city_name
    self.county = first_candidate.metadata.county_name
    self.state_abbreviation = first_candidate.components.state_abbreviation
    self.country_code = "US"
    self.postal_code = first_candidate.components.zipcode
    self.plus4_code = first_candidate.components.plus4_code
    self.latitude = first_candidate.metadata.latitude
    self.longitude = first_candidate.metadata.longitude
    self.time_zone = first_candidate.metadata.time_zone
    self.congressional_district = first_candidate.metadata.congressional_district
  end
end