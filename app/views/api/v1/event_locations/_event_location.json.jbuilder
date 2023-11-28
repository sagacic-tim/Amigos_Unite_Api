json.extract! event_location, 
  :id,
  :business_name,
  :phone,
  :address, 
  :address_type, 
  :room_suite_no,
  :floor, 
  :building, 
  :street_predirection, 
  :street_number, 
  :street_name, 
  :street_postdirection, 
  :street_suffix, 
  :apartment_suite_number, 
  :city, 
  :county, 
  :state_abbreviation, 
  :country_code, 
  :postal_code, 
  :plus4_code, 
  :latitude, 
  :longitude, 
  :time_zone,

  if event_location.location_image.attached?
    resized_image = event_location.location_image.variant(resize: "640x480").processed
    json.location_image_url rails_representation_url(resized_image, only_path: true)
  end

json.created_at event_location.created_at
json.updated_at event_location.updated_at
