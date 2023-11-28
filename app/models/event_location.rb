class EventLocation < ApplicationRecord
  
  belongs_to :event
  has_one_attached :location_image
  before_save :validate_address_with_smartystreets
  before_save :scan_for_viruses
  # Trigger the job after commit (i.e., after the record and its image have been saved)
  after_commit :process_location_image, on: [:create, :update]

  validates :business_name, allow_blank: true, length: { maximum: 64 }, uniqueness: { case_sensitive: false }
  validates :phone, phone: { possible: true, allow_blank: true, types: [:voip, :mobile, :fixed_line] }
  validates :location_image, attached: true, 
  content_type: ['image/png', 'image/jpg', 'image/jpeg'],
  size: { less_than: 5.megabytes }

  private

  def validate_address_with_smartystreets
    raw_address = "#{self.street_number} #{self.street_name} #{self.street_suffix} #{self.city}, #{self.state_abbreviation} #{self.postal_code}"
    # Call SmartyStreets API to validate the address
    puts "Validating address: #{raw_address}"
    # Fetching credentials
    smarty_streets_credentials = Rails.application.credentials.smarty_streets
    auth_id = smarty_streets_credentials[:auth_id]
    auth_token = smarty_streets_credentials[:auth_token]
    puts "Auth ID: #{auth_id}, Auth Token: #{auth_token}"

    # Initialize the client with the correct credentials
    credentials = SmartyStreets::StaticCredentials.new(auth_id, auth_token)
    client = SmartyStreets::ClientBuilder.new(credentials).build_us_street_api_client
    # Pass the address string as an argument
    lookup = SmartyStreets::USStreet::Lookup.new(raw_address)
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
  end

  def update_location_attributes(candidate)
    self.address = "#{candidate.components.primary_number} #{candidate.components.street_predirection} #{candidate.components.street_name} #{candidate.components.street_suffix} #{candidate.components.street_postdirection} #{candidate.components.secondary_number} #{candidate.components.city_name}, #{candidate.components.state_abbreviation} US #{candidate.components.zipcode}-#{candidate.components.plus4_code}"
    self.address_type = candidate.metadata.rdi
    self.room_suite_no = candidate.components.secondary
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
  end

  def scan_for_viruses
    return unless location_image.attached?

    unless Clamby.safe?(location_image.path)
      location_image.purge
      errors.add(:location_image, "Virus detected in file.")
      throw :abort
    end
  end

  def process_location_image
    # Enqueue the job only if the location_image is attached
    ProcessLocationImageJob.perform_later(self) if location_image.attached?
  end
end
