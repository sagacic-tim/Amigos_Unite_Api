# app/models/event_amigo_connector.rb
class EventAmigoConnector < ApplicationRecord
  belongs_to :amigo
  belongs_to :event

  enum role: {
    participant: 0,
    assistant_coordinator: 1,
    lead_coordinator: 2
  }

  enum status: {
    pending: 0,
    confirmed: 1,
    declined: 2
  }, _prefix: true

  # Validations
  validates :amigo_id, :event_id, :role, :status, presence: true
  validates :amigo_id, uniqueness: { scope: :event_id, message: "is already assigned to this event" }

  # Scopes
  scope :coordinators, -> { where(role: [:lead_coordinator, :assistant_coordinator]) }
  scope :active, -> { status_confirmed }

  # Callbacks
  before_validation :set_default_status, on: :create

  # Instance Methods
  def coordinator?
    assistant_coordinator? || lead_coordinator?
  end

  private

  def set_default_status
    self.status ||= :pending
  end
end
