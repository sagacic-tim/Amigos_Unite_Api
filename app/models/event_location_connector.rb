# app/models/event_location_connector.rb

class EventLocationConnector < ApplicationRecord
  belongs_to :event
  belongs_to :event_location

  enum status: {
    pending: 0,
    confirmed: 1,
    active: 2,
    rejected: 3
  }

  validates :event_location_id, uniqueness: { scope: :event_id }
  validates :status, presence: true
  validates :event_id,
    uniqueness: {
      conditions: -> { where(is_primary: true) },
      message: "already has a primary location"
    },
    if: :is_primary?

  # Automatically set default status:
  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :pending
  end
end
