class AmigoLocation < ApplicationRecord
  
  belongs_to :amigo
  before_save :validate_address_with_smartystreets

  def validate_address_with_google_maps
    raw_address = "#{self.street_number} #{self.street_name} #{self.city}, #{self.state_abbreviation} #{self.postal_code}"
    # Call SmartyStreets API to validate the address
    puts "Validating address: #{raw_address}"
    # Fetching credentials
    api_key = Rails.application.credentials.google_maps[:api_key]
    url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=#{URI.encode_www_form_component(raw_address)}&inputtype=textquery&key=#{api_key}"

  
    response = HTTParty.get(url)
    if response.success?
      result = response.parsed_response["candidates"].first
      if result
        update_location_attributes_with_google_maps(result)
      else
        puts 'No valid address candidates found by Google Maps.'
        errors.add(:base, 'No valid address candidates found.')
        throw(:abort)
      end
    else
      puts "Google Maps API call failed with error: #{response.message}"
      errors.add(:base, "Address validation failed with error: #{response.message}")
      throw(:abort)
    end
  end

  private

  def update_location_attributes_with_google_maps(result)
    self.address = result["formatted_address"]
    components = result['address_components']
    components.each do |component|
      case component['types'].first
        when 'street_number'
          self.street_number = component['long_name']
        when 'route'
          self.street_name = component['long_name']
        when 'subpremise'
          self.apartment_suite_number = component['long_name']
        when 'room'
          self.room_no = component['long_name']
        when 'locality'
          self.city = component['long_name']
        when 'sublocality'
          self.sublocality = component['long_name']
        when 'administrative_area_level_2'
          self.county = component['long_name']
        when 'administrative_area_level_1'
          self.state_abbreviation = component['short_name']
        when 'country'
          self.country_code = component['short_name']
        when 'postal_code'
          self.postal_code = component['long_name']
        when 'postal_code_suffix'
          self.plus4_code = component['long_name']
        when 'establishment'
          self.address_type = component['long_name']
        when 'floor'
          self.floor = component['long_name']
        when 'post_box'
          self.po_box = component['long_name']
      end
    end
    self.latitude = result["geometry"]["location"]["lat"]
    self.longitude = result["geometry"]["location"]["lng"]
  end
end