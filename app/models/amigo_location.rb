class AmigoLocation < ApplicationRecord
  
  belongs_to :amigo
  before_save :validate_address_with_smartystreets

  def validate_address_with_smartystreets
    raw_address = "#{self.street_number} #{self.street_name} #{self.street_suffix} #{self.city}, #{self.state_abbreviation} #{self.postal_code}"
    # Call SmartyStreets API to validate the address
    puts "Validating address: #{raw_address}"
    smarty_streets_credentials = Rails.application.credentials.smarty_streets
    auth_id = smarty_streets_credentials[:auth_id]
    auth_token = smarty_streets_credentials[:auth_token]
    puts "Auth ID: #{auth_id}\n\nAuth Token: #{auth_token}"
    client = SmartyStreets::ClientBuilder.new(
      SmartyStreets::StaticCredentials.new(credentials[:auth_id], credentials[:auth_token])
    ).build_us_street_api_client
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
      update_location_attributes(result[0])
    end

    def update_location_attributes(candidate)
      self.address = "#{candidate.components.primary_number} #{first_candidate.components.street_predirection} #{first_candidate.components.street_name} #{first_candidate.components.street_suffix} #{first_candidate.components.street_postdirection} #{first_candidate.components.secondary_number} #{first_candidate.components.city_name}, #{first_candidate.components.state_abbreviation} US #{first_candidate.components.zipcode}-#{first_candidate.components.plus4_code}"
      self.address_type = candidate.metadata.rdi
      self.building = candidate.components.extra_secondary_number
      self.street_number = candidate.components.primary_number
      self.street_predirection = candidate.components.street_predirection
      self.street_name = candidate.components.street_name
      self.street_postdirection = candidate.components.street_postdirection
      self.street_suffix = candidate.components.street_suffix
      self.apartment_suite_number = candidate.components.secondary_number
      self.city = candidate.components.city_name
      self.county = candidate.metadata.county_name
      self.state_abbreviation = candidate.components.state_abbreviation
      self.country_code = "US"
      self.postal_code = candidate.components.zipcode
      self.plus4_code = candidate.components.plus4_code
      self.latitude = candidate.metadata.latitude
      self.longitude = candidate.metadata.longitude
      self.time_zone = candidate.metadata.time_zone
      self.congressional_district = candidate.metadata.congressional_district
    end
  end