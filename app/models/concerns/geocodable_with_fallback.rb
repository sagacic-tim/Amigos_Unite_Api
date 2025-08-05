# app/models/concerns/geocodable_with_fallback.rb
module GeocodableWithFallback
  extend ActiveSupport::Concern

  included do
    before_validation :geocode_with_fallback
    before_validation :build_full_address
  end

  private

  # 1. Geocode the address using partial data if coordinates are not already set
  def geocode_with_fallback
    return if latitude.present? && longitude.present?

    input_address = build_input_address_for_geocoding
    if input_address.blank?
      log_and_add_error("Insufficient data to geocode address.")
      return
    end

    Rails.logger.info "[Geocoder] Resolving partial address: #{input_address}"

    results = GeocoderWithFallback.search_with_fallback(input_address)

    if results.any?
      save_address_components(results.first)
      fetch_time_zone if latitude.present? && longitude.present?
    else
      log_and_add_error("Geocoding failed for address: #{input_address}")
    end
  rescue StandardError => e
    log_and_add_error("Geocoding error: #{e.message}")
  end

  # 2. Fetch timezone from Google based on coordinates
  def fetch_time_zone
    return unless latitude.present? && longitude.present?

    uri = URI("https://maps.googleapis.com/maps/api/timezone/json")
    uri.query = URI.encode_www_form(
      location: "#{latitude},#{longitude}",
      timestamp: Time.now.to_i,
      key: Rails.application.credentials.google_maps
    )

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      self.time_zone = data["timeZoneId"]
    else
      log_and_add_error("Failed to fetch time zone: HTTP #{response.code}")
    end
  rescue => e
    log_and_add_error("Time zone fetch error: #{e.message}")
  end

  # 3. Extract lat/lng and address parts into individual fields
  def save_address_components(result)
    if loc = result.data.dig("geometry", "location")
      self.latitude = loc["lat"]
      self.longitude = loc["lng"]
    end

    mappings = {
      'floor' => :floor,
      'room' => :room_no,
      'subpremise' => :apartment_suite_number,
      'street_number' => :street_number,
      'route' => :street_name,
      'sublocality' => :city_sublocality,
      'locality' => :city,
      'administrative_area_level_2' => :state_province_subdivision,
      'administrative_area_level_1' => [:state_province, :state_province_short],
      'country' => [:country, :country_short],
      'postal_code' => :postal_code,
      'postal_code_suffix' => :postal_code_suffix,
      'post_box' => :post_box
    }

    result.data["address_components"].each do |component|
      type = component["types"].first
      mapping = mappings[type]
      next unless mapping

      if mapping.is_a?(Array)
        self[mapping[0]] = component["long_name"] if respond_to?("#{mapping[0]}=")
        self[mapping[1]] = component["short_name"] if respond_to?("#{mapping[1]}=")
      else
        self[mapping] = component["long_name"] if respond_to?("#{mapping}=")
      end
    end
  end

  # 4. Prepare a partial address string for geocoding input
  def build_input_address_for_geocoding
    parts = []
    parts << street_number if respond_to?(:street_number) && street_number.present?
    parts << street_name if respond_to?(:street_name) && street_name.present?
    parts << city if respond_to?(:city) && city.present?

    state = respond_to?(:state_province_short) ? state_province_short : (respond_to?(:state_province) ? state_province : nil)
    parts << state if state.present?

    country = respond_to?(:country_short) ? country_short : (respond_to?(:country) ? country : nil)
    parts << country if country.present?

    parts << postal_code if respond_to?(:postal_code) && postal_code.present?

    parts.compact.join(', ')
  end

  # 5. Construct the printable full address from populated fields
  def build_full_address
    formatted_postal = if respond_to?(:postal_code)
                         [postal_code, (respond_to?(:postal_code_suffix) ? postal_code_suffix.presence : nil)].compact.join('-')
                       end

    components = []
    components << street_number if respond_to?(:street_number) && street_number.present?
    components << street_name if respond_to?(:street_name) && street_name.present?
    components << apartment_suite_number if respond_to?(:apartment_suite_number) && apartment_suite_number.present?
    components << city if respond_to?(:city) && city.present?
    components << state_province_short if respond_to?(:state_province_short) && state_province_short.present?
    components << country_short if respond_to?(:country_short) && country_short.present?
    components << formatted_postal if formatted_postal.present?

    self.address = components.compact.join(', ') unless components.empty?
  end

  # 6. Centralized logging and error tracking
  def log_and_add_error(message)
    Rails.logger.error(message)
    errors.add(:base, message)
    throw(:abort)
  end
end
