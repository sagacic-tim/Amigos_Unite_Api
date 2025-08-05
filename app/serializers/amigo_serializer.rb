# app/serializers/amigo_serializer.rb
class AmigoSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id,
             :first_name,
             :last_name,
             :user_name,
             :email,
             :secondary_email,
             :phone_1,
             :phone_2,
             :avatar_url,
             :created_at,
             :updated_at,
             :full_name,
             :formatted_created_at,
             :formatted_updated_at

  has_one :amigo_detail
  has_many :amigo_locations

  def formatted_created_at
    return nil unless object.created_at
    object.created_at.strftime("%F %T %Z")
  end

  def phone_1
    return nil unless object.phone_1.present?
    Phonelib.parse(object.phone_1).international
  end

  def phone_2
    return nil unless object.phone_2.present?
    Phonelib.parse(object.phone_2).international
  end

  def avatar_url
    if object.avatar.attached?
      rails_blob_url(object.avatar, host: Rails.application.config.default_url_options[:host])
    else
      ActionController::Base.helpers.asset_url('default-amigo-avatar.png', host: Rails.application.config.default_url_options[:host])
    end
  end

  def full_name
    "#{object.first_name} #{object.last_name}".strip
  end

  def formatted_created_at
    object.created_at.strftime("%Y-%m-%d %H:%M:%S")
  end

  def formatted_updated_at
    object.updated_at.strftime("%Y-%m-%d %H:%M:%S")
  end
end
