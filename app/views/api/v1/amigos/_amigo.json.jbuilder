# app/views/api/v1/amigos/_amigo.json.jbuilder

json.extract! amigo,
              :id,
              :first_name,
              :last_name,
              :user_name,
              :email,
              :secondary_email,
              :phone_1,
              :phone_2,
              :created_at,
              :updated_at

json.avatar_url url_for(amigo.avatar) if amigo.avatar.attached?

# Add event roles
json.event_roles amigo.event_roles