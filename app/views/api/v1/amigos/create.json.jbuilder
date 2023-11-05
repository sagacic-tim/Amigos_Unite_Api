# app/views/api/v1/amigos/create.json.jbuilder

if @amigo.persisted?
  json.partial! 'api/v1/amigos/amigo', amigo: @amigo
else
  json.errors @amigo.errors.full_messages
end