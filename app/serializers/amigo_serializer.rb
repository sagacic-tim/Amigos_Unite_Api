class AmigoSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :user_name, :email, :secondary_email, :phone_1, :phone_2, :avatar_url, :created_at, :updated_at

  def avatar_url
    object.avatar.attached? ? Rails.application.routes.url_helpers.rails_blob_url(object.avatar, only_path: true) : nil
  end
end