json.array! @amigos do |amigo|
  json.partial! 'api/v1/amigos/amigo', amigo: amigo
end