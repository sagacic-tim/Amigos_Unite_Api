class EventLocationConnector < ApplicationRecord
  belongs_to :event
  belongs_to :event_location

  enum status: {
    pending: 0,
    confirmed: 1,
    rejected: 2
  }

  validates :status, presence: true

  # Automatically set default status
  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :pending
  end
end
