# app/services/events/change_role.rb
module Events
  class ChangeRole
    # actor: Amigo performing the change
    # event: Event
    # target: Amigo whose role changes
    # new_role: :participant | :assistant_coordinator
    raise NotAuthorizedError unless policy.manage_roles?

    def call(actor:, event:, target:, new_role:)
      policy = EventPolicy.new(actor, event)
      raise NotAuthorizedError unless policy.manage_roles?

      role_sym = new_role.to_sym
      if role_sym == :lead_coordinator
        raise ArgumentError, "Use Events::TransferLead for lead promotions"
      end

      conn = event.event_amigo_connectors.find_by!(amigo_id: target.id)
      conn.update!(role: role_sym)
      conn
    end
  end
end

