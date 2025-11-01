
# app/services/events/transfer_lead.rb
module Events
  class TransferLead

    raise NotAuthorizedError unless policy.manage_roles?

    # actor must be admin or current lead
    def call(actor:, event:, new_lead:)
      policy = EventPolicy.new(actor, event)
      raise NotAuthorizedError unless policy.manage_roles?

      Event.transaction do
        e = Event.lock.find(event.id)
        conns = e.event_amigo_connectors.lock

        current_lead = conns.find_by!(role: :lead_coordinator)
        raise "Invariant mismatch" unless current_lead.amigo_id == e.lead_coordinator_id

        target = conns.find_or_create_by!(amigo_id: new_lead.id) do |c|
          c.role = :participant
        end

        current_lead.update!(role: :assistant_coordinator)
        target.update!(role: :lead_coordinator)
        e.update!(lead_coordinator_id: new_lead.id)

        target
      end
    end
  end
end
