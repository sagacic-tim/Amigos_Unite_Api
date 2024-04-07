class EventAmigoConnector < ApplicationRecord
  belongs_to :amigo
  belongs_to :event

  enum role: {
    participant: 0,
    assistant_coordinator: 1,
    lead_coordinator: 2
  }
end
