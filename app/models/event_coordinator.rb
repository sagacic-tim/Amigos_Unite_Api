class EventCoordinator < ApplicationRecord
  belongs_to :event
  belongs_to :amigo

  # 'is_active' indicates if the coordinator is currently active
  validates :is_active, inclusion: { in: [true, false] }

  # Uniqueness validation
  validates :amigo_id, uniqueness: { scope: :event_id, message: "is already a coordinator for this event" }
end