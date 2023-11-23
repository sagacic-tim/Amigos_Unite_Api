class EventCoordinator < ApplicationRecord
  belongs_to :event
  belongs_to :amigo

  # 'is_active' indicates if the coordinator is currently active in
  # their role as coordinator
  validates :is_active, inclusion: { in: [true, false] }

  # Optional: Validate uniqueness of Amigo per Event
  validates :amigo_id, uniqueness: { scope: :event_id, message: "is already a coordinator for this event" }
end
