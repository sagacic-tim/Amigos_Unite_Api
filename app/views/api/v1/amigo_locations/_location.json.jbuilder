# app/views/api/v1/amigo_locations/_location.json.jbuilder

json.extract! location,
:id,
:address,
:address_type,
:floor,
:building,
:street_number,
:street_predirection,
:street_name,
:street_suffix,
:street_postdirection,
:apartment_number,
:city,
:county,
:state_abbreviation,
:country_code,
:postal_code,
:plus4_code,
:latitude,
:longitude,
:time_zone,
:congressional_district,
:created_at,
:updated_at