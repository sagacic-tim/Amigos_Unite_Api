class EventLocationConnector < ApplicationRecord
  belongs_to :event
  belongs_to :event_location
end