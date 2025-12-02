# app/services/events/create_event.rb
module Events
  class CreateEvent
    # creator: Amigo who is creating the event (becomes lead coordinator)
    # attrs:   { event_name:, event_date:, event_time:, event_type:, event_speakers_performers: (String|Array<String>) }
    def call(creator:, attrs:)
      Event.transaction do
        # --- Coerce/normalize incoming attributes ---------------------------------
        cleaned = attrs.to_h.deep_dup.symbolize_keys

        # Normalize date/time
        if cleaned.key?(:event_date) && cleaned[:event_date].present?
          cleaned[:event_date] = Date.parse(cleaned[:event_date].to_s)
        end
        if cleaned.key?(:event_time) && cleaned[:event_time].present?
          cleaned[:event_time] = cleaned[:event_time].to_s
        end

        # Normalize speakers/performers based on the actual column type
        if cleaned.key?(:event_speakers_performers)
          col = Event.column_for_attribute(:event_speakers_performers)
          if col.respond_to?(:array) && col.array
            # PostgreSQL text[] column
            cleaned[:event_speakers_performers] =
              Array(cleaned[:event_speakers_performers]).map(&:to_s).reject(&:blank?)
          else
            # Scalar text/varchar fallback
            cleaned[:event_speakers_performers] =
              Array(cleaned[:event_speakers_performers]).map(&:to_s).reject(&:blank?).join(", ")
          end
        end

        # Assign lead BEFORE the first save to satisfy NOT NULL and DB FK
        event = Event.new(cleaned.merge(lead_coordinator_id: creator.id))
        event.save!

        # Create the enforcing connector row (unique partial index => one lead per event)
        event.event_amigo_connectors.find_or_create_by!(
          amigo: creator,
          role:  :lead_coordinator
        )

        event
      end
    end
  end
end
