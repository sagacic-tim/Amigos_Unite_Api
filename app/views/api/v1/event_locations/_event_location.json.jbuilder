json.extract! event_location, 
  :id, 
  :address, 
  :address_type, 
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
  :time_zone

json.created_at event_location.created_at
json.updated_at event_location.updated_at
