class AmigoSerializer
  include JSONAPI::Serializer
  attributes :id, :first_name, :last_name, :email, :user_name, :created_at, :updated_at
end