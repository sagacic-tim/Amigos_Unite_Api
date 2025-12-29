# app/services/events/create_event.rb
require "open-uri"
require "securerandom"

module Events
  class CreateEvent
    # creator: Amigo who is creating the event (becomes lead coordinator)
    # attrs:   params[:event] (may include a nested :location hash)
    #
    # Expected shape for attrs[:location] (symbolized):
    # {
    #   business_name:              String,
    #   location_type:              String,
    #   street_number:              String,
    #   street_name:                String,
    #   city:                       String,
    #   state_province:             String,
    #   country:                    String,
    #   postal_code:                String,
    #   owner_name:                 String,
    #   owner_phone:                String,
    #   capacity:                   Integer,
    #   capacity_seated:            Integer,
    #   availability_notes:         String,
    #   has_food:                   Boolean,
    #   has_drink:                  Boolean,
    #   has_internet:               Boolean,
    #   has_big_screen:             Boolean,
    #   place_id:                   String,
    #   location_image_attribution: String,
    #   image_url:                  String, # transient
    #   photo_reference:            String  # transient
    # }
    #
    def call(creator:, attrs:)
      Event.transaction do
        cleaned = attrs.to_h.deep_dup.deep_symbolize_keys

        # Extract nested location before building the Event.
        location_attrs = cleaned.delete(:location)

        normalize_event_date_time!(cleaned)
        normalize_speakers!(cleaned)

        # Assign lead BEFORE the first save to satisfy NOT NULL and DB FK
        event = Event.new(cleaned.merge(lead_coordinator_id: creator.id))
        event.save!

        # Create the enforcing connector row (unique partial index => one lead per event)
        event.event_amigo_connectors.find_or_create_by!(
          amigo: creator,
          role:  :lead_coordinator
        )

        # Upsert primary location if the payload is meaningful
        if location_attrs.present?
          Events::UpsertPrimaryLocation.new.call(
            event:     event,
            raw_attrs: location_attrs
          )
        end

        event

      end
    end

    private

    # --- Normalizers --------------------------------------------------------

    def normalize_event_date_time!(attrs)
      if attrs.key?(:event_date) && attrs[:event_date].present?
        attrs[:event_date] = Date.parse(attrs[:event_date].to_s)
      end

      if attrs.key?(:event_time) && attrs[:event_time].present?
        attrs[:event_time] = attrs[:event_time].to_s
      end
    end

    def normalize_speakers!(attrs)
      return unless attrs.key?(:event_speakers_performers)

      col = Event.column_for_attribute(:event_speakers_performers)

      if col.respond_to?(:array) && col.array
        # PostgreSQL text[] column
        attrs[:event_speakers_performers] =
          Array(attrs[:event_speakers_performers]).map(&:to_s).reject(&:blank?)
      else
        # Scalar text/varchar fallback
        attrs[:event_speakers_performers] =
          Array(attrs[:event_speakers_performers]).map(&:to_s).reject(&:blank?).join(", ")
      end
    end
end
