class AmigoSerializer
  include JSONAPI::Serializer
  attributes :id, :user_name, :email, :phone_1, :first_name, :last_name
end