# app/serializers/amigo_serializer.rb
class AmigoSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :first_name, :last_name, :user_name, :email,
             :secondary_email, :phone_1, :phone_2, :avatar_url,
             :full_name, :formatted_created_at, :formatted_updated_at

  has_one  :amigo_detail
  has_many :amigo_locations

  def formatted_created_at
    object.created_at&.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_updated_at
    object.updated_at&.strftime("%Y-%m-%d %H:%M:%S")
  end

  def full_name
    [object.first_name, object.last_name].compact.join(' ').strip
  end

  def phone_1
    return nil if object.phone_1.blank?
    Phonelib.parse(object.phone_1).international
  end

  def phone_2
    return nil if object.phone_2.blank?
    Phonelib.parse(object.phone_2).international
  end

  # IMPORTANT: nil when no avatar, relative path when present
  def avatar_url
    return nil unless object.avatar.attached?
    rails_blob_path(object.avatar, only_path: true)
  end
end
