# app/model/event_location.rb

class EventLocation < ApplicationRecord
  include GeocodableWithFallback

  # ====================
  # Associations
  # ====================
  has_many :event_location_connectors, dependent: :destroy
  has_many :events, through: :event_location_connectors
  has_many_attached :images
  has_one_attached :location_image

    # If you want typed access to services:
  def services_hash
    (services || {}).symbolize_keys
  end

  def service_enabled?(key)
    !!services_hash[key.to_sym]
  end

  def location_image_url
    return unless location_image.attached?

    Rails.application.routes.url_helpers.url_for(location_image)
  end

  # ====================
  # Enums
  # ====================
  enum status: {
    pending: 0,
    verified: 1,
    rejected: 2
  }

  # ====================
  # Validations
  # ====================
  validates :business_name, length: { maximum: 64 }
  validates :business_phone, length: { maximum: 15 }

  validates :floor, length: { maximum: 10 }
  validates :room_no, :apartment_suite_number, :street_number, length: { maximum: 32 }
  validates :street_name, :city_sublocality, :state_province_subdivision, length: { maximum: 96 }
  validates :city, length: { maximum: 64 }
  validates :state_province, length: { maximum: 32 }
  validates :state_province_short, length: { maximum: 8 }
  validates :country, length: { maximum: 32 }
  validates :country_short, length: { maximum: 3 }
  validates :postal_code, length: { maximum: 12 }
  validates :postal_code_suffix, length: { maximum: 6 }
  validates :post_box, length: { maximum: 12 }
  validates :time_zone, length: { maximum: 48 }

  # Allow nil if geocoding may populate later; make strict if you require presence.
  validates :latitude,
    numericality: { greater_than_or_equal_to: -90,  less_than_or_equal_to: 90 },
    allow_nil: true

  validates :longitude,
    numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 },
    allow_nil: true
end
