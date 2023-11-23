class EventParticipant < ApplicationRecord
  belongs_to :amigo
  belongs_to :event
end
