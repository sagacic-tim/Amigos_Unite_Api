# app/views/api/v1/amigos/_amigo.json.jbuilder

json.extract! amigo,

:id,
:first_name,
:last_name,
:user_name,
:primary_email,
:secondary_email,
:phone_1,
:phone_2,
:date_of_birth,
:member_in_good_standing,
:available_to_host,
:willing_to_donate,
:personal_bio,
:created_at,
:updated_at