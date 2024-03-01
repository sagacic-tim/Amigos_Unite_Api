class AmigoLocation < ApplicationRecord
  belongs_to :amigo

  before_save :validate_address_with_google_maps

  private

  def validate_address_with_google_maps
    gmaps = GoogleMapsService::Client.new

    # Attempt to find the place
    results = gmaps.find_place(input: build_raw_address, input_type: 'textquery', fields: ['place_id'])

    if results[:status] == 'OK' && results[:candidates].any?
      place_id = results[:candidates].first[:place_id]
      
      # Get detailed place information using the place_id
      details = gmaps.place(place_id: place_id, fields: ['address_component', 'formatted_address', 'geometry'])

      if details[:status] == 'OK'
        process_google_maps_response(details[:result])
      else
        log_and_add_error("Failed to fetch detailed address information")
      end
    else
      log_and_add_error("No valid address candidates found")
    end
  rescue => e
    log_and_add_error("Google Maps API error: #{e.message}")
  end

  def build_raw_address
    "#{street_number} #{street_name} #{city}, #{state_abbreviation} #{postal_code}"
  end

  def process_google_maps_response(result)
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

  def log_and_add_error(message)
    Rails.logger.error message
    errors.add(:base, message)
    throw(:abort)
  end
end