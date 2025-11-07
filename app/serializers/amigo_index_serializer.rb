
# app/serializers/amigo_index_serializer.rb
class AmigoIndexSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :user_name, :email, :phone_1, :phone_2, :avatar_url, :full_name

  def full_name
    [object.first_name, object.last_name].compact.join(' ').strip
  end

  def phone_1
    present_and_format_phone(object.phone_1)
  end

  def phone_2
    present_and_format_phone(object.phone_2)
  end

  def avatar_url
    # Single source of truth in the model (handles default/gravatar/upload + cache buster)
    object.avatar_url_with_buster
  end

  private

  def present_and_format_phone(raw)
    return nil if raw.blank?
    Phonelib.parse(raw).international
  end
end
