json.extract! location,
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
  
  # Include events at this location
  json.events event_location.events do |event|
    json.extract! event, :id, :event_name, :event_date, :event_time
    json.coordinator event.coordinator.user_name
  end