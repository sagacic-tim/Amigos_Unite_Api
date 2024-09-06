class AmigoSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :user_name, :email, :secondary_email, :phone_1, :phone_2, :avatar_url, :created_at, :updated_at

  def phone_1
    Phonelib.parse(object.unformatted_phone_1).international
  end

  def phone_2
    Phonelib.parse(object.unformatted_phone_2).international
  end

  def avatar_url
    if object.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(object.avatar, only_path: true)
    else
      ActionController::Base.helpers.asset_path('default-amigo-avatar.png') # or the appropriate path to the default avatar
    end
  end
end
