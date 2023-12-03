json.extract! event_location, 
  :id,
  :business_name,
  :phone,
  :address,
  :address_type,
  :floor,
  :street_number,
  :street_name,
  :room_no,
  :apartment_suite_number,
  :sublocality,
  :city,
  :county,
  :state_abbreviation,
  :country_code,
  :postal_code,
  :plus4_code,
  :latitude,
  :longitude,
  :time_zone,
  :created_at,
  :updated_at

  if event_location.location_image.attached?
    resized_image = event_location.location_image.variant(resize: "640x480").processed
    json.location_image_url rails_representation_url(resized_image, only_path: true)
  end

json.created_at event_location.created_at
json.updated_at event_location.updated_at
