class EventLocation < ApplicationRecord
  require 'net/http'
  require 'json'

  # Associations
  has_many :event_location_connectors
  has_many :events, through: :event_location_connectors

  # Validations
  validates :business_name, length: {maximum: 64}
  validates :business_phone, length: {maximum: 15}
  validates :floor, length: { maximum: 10 }
  validates :room_no, length: { maximum: 32 }
  validates :apartment_suite_number, length: { maximum: 32 }
  validates :street_number, length: { maximum: 32 }
  validates :street_name, length: { maximum: 96 }
  validates :city_sublocality, length: { maximum: 96 }
  validates :city, length: { maximum: 64 }
  validates :state_province_subdivision, length: { maximum: 96 }
  validates :state_province, length: { maximum: 32 }
  validates :state_province_short, length: { maximum: 8 }
  validates :country, length: { maximum: 32 }
  validates :country_short, length: { maximum: 3 }
  validates :postal_code, length: { maximum: 12 }
  validates :postal_code_suffix, length: { maximum: 6 }
  validates :post_box, length: { maximum: 12 }
  validates :latitude , numericality: { greater_than_or_equal_to:  -90, less_than_or_equal_to:  90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :time_zone, length: { maximum: 48 }

  before_validation :fetch_detailed_address_components
  before_validation :build_full_address

  private

  def fetch_detailed_address_components
    uri = URI("https://maps.googleapis.com/maps/api/geocode/json")
    uri.query = URI.encode_www_form(address: build_raw_address, key: Rails.application.credentials.google_maps_api_key)
    
    response = Net::HTTP.get_response(uri)
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      if data['status'] == 'OK'
        result = data['results'].first
        save_address_components(result)
        fetch_time_zone
      else
        errors.add(:address, 'could not be geocoded')
      end
    else
      errors.add(:base, 'Geocoding request failed')
    end
  rescue JSON::ParserError => e
    log_and_add_error("Geocoding error: #{e.message}")
  end

  def fetch_time_zone
    # Assuming latitude and longitude have already been assigned
    uri = URI("https://maps.googleapis.com/maps/api/timezone/json")
    uri.query = URI.encode_www_form({
      location: "#{latitude},#{longitude}",
      timestamp: Time.now.to_i,
      key: Rails.application.credentials.google_maps_api_key
    })
    
    response = Net::HTTP.get_response(uri)
    
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      self.time_zone = data["timeZoneId"]
    end
  rescue => e
    log_and_add_error("Time Zone fetch error: #{e.message}")
  end
  def save_address_components(result)
    components = result['address_components']
    if lat_lng = result.dig('geometry', 'location')
      Rails.logger.info "Latitude: #{lat_lng['lat'].inspect}, Longitude: #{lat_lng['lng'].inspect}"
      # result.geometry.location.lat, result.geometry.location.lng  
      # Convert to float and check for validity
      latitude = lat_lng['lat'].to_f
      longitude = lat_lng['lng'].to_f
  
      if latitude.between?(-90, 90) && longitude.between?(-180, 180)
        self.latitude = latitude
        self.longitude = longitude
      else
        Rails.logger.error "Invalid latitude or longitude: #{latitude}, #{longitude}"
        # You can raise an error here if you want to stop the process and investigate
        # raise "Invalid latitude or longitude: #{latitude}, #{longitude}"
      end
    end

    # Google Geocoder to Database mapping
    component_mappings = {
      'floor' => :floor,
      'room' => :room_no,
      'subpremise' => :apartment_suite_number,
      'street_number' => :street_number,
      'route' => :street_name,
      'sublocality' => :city_sublocality, # i.e. burrough, district
      'locality'=> :city,
      'administrative_area_level_2' => :state_province_subdivision, # i.e. county
      'administrative_area_level_1' => [:state_province, :state_province_short],
      'country' => [:country, :country_short],
      'postal_code' => :postal_code,
      'postal_code_suffix' => :postal_code_suffix,
      'post_box' => :po_box
    }
    
    components.each do |component|
      type = component['types'].first
      if component_mappings[type]
        # Here, we're checking if the mapping returns an array (for both long and short name fields)
        mapping = component_mappings[type]
        if mapping.is_a?(Array)
          long_name_field, short_name_field = mapping
          self.send("#{long_name_field}=", component['long_name']) if self.respond_to?("#{long_name_field}=")
          self.send("#{short_name_field}=", component['short_name']) if short_name_field && self.respond_to?("#{short_name_field}=")
        else
          # For single field mappings, assign the long name as default
          self.send("#{mapping}=", component['long_name']) if self.respond_to?("#{mapping}=")
        end
      end
    end
  end

  def build_raw_address
    "#{street_number} #{street_name} #{city}, #{state_province_short}, #{country_short} #{postal_code}#{postal_code_suffix.present? ? '-' + postal_code_suffix : ''}"
  end


  def build_full_address
    # Components are listed in the order they should appear in the full address.

    postal_code_with_suffix = [postal_code, postal_code_suffix.presence].compact.join('-')

    components = [
      street_number,
      street_name,
      apartment_suite_number.presence, # Optional component
      city,
      state_province_short,
      country_short,
      postal_code_with_suffix # Use the combined postal code and plus4 code
    ].compact.join(', ') # Removes any nil values and joins the components with ', '
  
    self.address = components unless components.blank?
  end

  # Log error message and add it to the model's errors
  def log_and_add_error(message)
    Rails.logger.error message
    errors.add(:base, message)
    throw(:abort)
  end
end