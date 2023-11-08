# app/views/api/v1/amigos/create.json.jbuilder

if @amigo.errors.any?
  json.errors @amigo.errors.full_messages
else
  json.partial! 'api/v1/amigos/amigo', amigo: @amigo
  # Assuming you are using token-based authentication and the token is available
  json.authentication_token @amigo.authentication_token if @amigo.respond_to?(:authentication_token)
end
