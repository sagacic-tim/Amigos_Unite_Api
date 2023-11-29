class EventLocationConnector < ApplicationRecord
  belongs_to :event
  belongs_to :event_location

  # Validations
  validates :event_id, presence: true
  validates :event_location_id, presence: true

  # Custom validation to ensure the existence of associated records
  validate :event_exists
  validate :event_location_exists

  private

  # Custom method to check if the associated event exists
  def event_exists
    errors.add(:event, 'must exist') unless Event.exists?(self.event_id)
  end

  # Custom method to check if the associated event location exists
  def event_location_exists
    errors.add(:event_location, 'must exist') unless EventLocation.exists?(self.event_location_id)
  end
end