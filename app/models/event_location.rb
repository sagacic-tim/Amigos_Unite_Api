class EventLocation < ApplicationRecord
  
  # Each event location can b e associagted with one or more events.
  # These associations are handle via the EventLocationConnector model
  has_many :event_location_connectors
  has_many :events, through: :event_location_connectors
  # each locaiton can have onbe attached image

  # validate with SmartyStreets. This will be swapped for
  # Google Places.
  before_save :validate_address_with_google_maps

  validates :business_name, allow_blank: true, length: { maximum: 64 }, uniqueness: { case_sensitive: false }
  validates :phone, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line] }
  # has_one_attached :location_image
  # Images will be scanned for viruses
  # before_save :scan_for_viruses
  # Make sure the image upload is an image file and not something else
  # and not some hemnongous gigabyte sized image.
  # Trigger the job after commit (i.e., after the record and its
  # image have been saved to scale adn crop it to 640 x 480 pixels)
  # after_commit :process_location_image, on: [:create, :update]
  # validates :location_image, attached: true, 
  # content_type: ['image/png', 'image/jpg', 'image/jpeg'],
  # size: { less_than: 5.megabytes }

  def validate_address_with_google_maps
    raw_address = "#{self.street_number} #{self.street_name} #{self.street_suffix} #{self.city}, #{self.state_abbreviation} #{self.postal_code}"
    # Call SmartyStreets API to validate the address
    puts "Validating address: #{raw_address}"
    # Fetching credentials
    api_key = Rails.application.credentials.google_maps[:api_key]
    url = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=#{URI.encode(raw_address)}&inputtype=textquery&key=#{api_key}"
  
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
        when 'room'
          self.room_no = component['long_name']
        when 'post_box'
          self.po_box = component['long_name']
      end
    end
    self.latitude = result["geometry"]["location"]["lat"]
    self.longitude = result["geometry"]["location"]["lng"]
  end

  # def scan_for_viruses
  #   return unless location_image.attached?

  #   unless Clamby.safe?(location_image.path)
  #     location_image.purge
  #     errors.add(:location_image, "Virus detected in file.")
  #     throw :abort
  #   end
  # end

  # def process_location_image
  #   # Enqueue the job only if the location_image is attached
  #   ProcessLocationImageJob.perform_later(self) if location_image.attached?
  # end
end
