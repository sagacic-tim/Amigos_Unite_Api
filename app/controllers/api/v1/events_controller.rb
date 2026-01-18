# app/controllers/api/v1/events_controller.rb
module Api
  module V1
    class EventsController < ApplicationController
      # Keep this if you rely on it elsewhere; safe to remove if unused.
      include ErrorHandling if defined?(ErrorHandling)

      # IMPORTANT:
      # Your ApplicationController already authenticates globally, but your specs
      # expect /events and /events/:id to be protected even if something changes
      # upstream. This makes the contract explicit for Events.
      before_action :authenticate_amigo!, except: [:mission_index]

      # CSRF is already enforced globally in ApplicationController for mutating API requests,
      # but keeping this makes the contract obvious and self-contained.
      before_action :verify_csrf_token, only: [:create, :update, :destroy]

      before_action :set_event, only: [:show, :update, :destroy]
      before_action :debug_authentication, if: -> { Rails.env.development? }

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      # GET /api/v1/events
      def index
        events = Event.all.order(created_at: :desc)
        render json: events.map { |e| event_payload(e) }, status: :ok
      rescue ActiveRecord::ConnectionNotEstablished
        render json: { error: "Database connection error." }, status: :service_unavailable
      end

      # GET /api/v1/events/:id
      def show
        render json: event_payload(@event, include_primary_location: true), status: :ok
      end

      # POST /api/v1/events
      def create
        policy = EventPolicy.new(current_amigo, nil)
        return render json: { error: "Unauthorized" }, status: :unauthorized unless policy.create?

        event = Events::CreateEvent.new.call(
          creator: current_amigo,
          attrs: event_params
        )

        render json: event_payload(event, include_primary_location: true), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end

      # PATCH/PUT /api/v1/events/:id
      def update
        return unless authorize_event!(@event, :update?)

        Event.transaction do
          # 1) Optional lead coordinator swap (this is a role change, so treat it as such)
          if params[:new_lead_coordinator_id].present?
            roles_policy = EventPolicy.new(current_amigo, @event)
            unless roles_policy.manage_roles?
              render json: { error: "Unauthorized" }, status: :unauthorized
              raise ActiveRecord::Rollback
            end

            new_id = params[:new_lead_coordinator_id].to_i

            @event.event_amigo_connectors.lead_coordinator
                  .where.not(amigo_id: new_id)
                  .delete_all

            @event.event_amigo_connectors
                  .find_or_initialize_by(amigo_id: new_id)
                  .update!(role: :lead_coordinator)

            @event.update!(lead_coordinator_id: new_id)
          end

          # 2) Split core event attrs from nested location
          raw_params     = event_params.to_h.deep_dup
          location_attrs = raw_params.delete("location") || raw_params.delete(:location)

          # 3) Update event core fields
          @event.update!(raw_params)

          # 4) Upsert primary location if provided
          if location_attrs.present?
            Events::UpsertPrimaryLocation.new.call(
              event: @event,
              raw_attrs: location_attrs
            )
          end
        end

        render json: event_payload(@event, include_primary_location: true), status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      end

      # DELETE /api/v1/events/:id
      def destroy
        return unless authorize_event!(@event, :destroy?)

        @event.destroy!
        render json: { message: "Event successfully deleted." }, status: :ok
      rescue ActiveRecord::RecordNotDestroyed => e
        render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
      end

      # GET /api/v1/events/my_events
      def my_events
        coordinator_roles = EventAmigoConnector.roles.values_at("lead_coordinator", "assistant_coordinator")

        events = Event
          .left_outer_joins(:event_amigo_connectors)
          .where(
            "events.lead_coordinator_id = :id OR " \
            "(event_amigo_connectors.amigo_id = :id AND event_amigo_connectors.role IN (:roles))",
            id: current_amigo.id,
            roles: coordinator_roles
          )
          .distinct
          .order(created_at: :desc)

        render json: events.map { |e| event_payload(e) }, status: :ok
      end

      # GET /api/v1/events/mission
      def mission_index
        render "api/v1/events/mission_index"
      end

      private

      def set_event
        @event = Event.find(params[:id])
      end

      def render_not_found(_e)
        render json: { error: "Event not found" }, status: :not_found
      end

      # FIX: return boolean so callers can `return unless authorize_event!(...)`
      # This prevents double-render errors.
      def authorize_event!(record, action)
        policy = EventPolicy.new(current_amigo, record)
        return true if policy.public_send(action)

        render json: { error: "Unauthorized" }, status: :unauthorized
        false
      end

      def debug_authentication
        return unless Rails.env.development?

        Rails.logger.debug "[EventsController##{action_name}] current_amigo: #{current_amigo&.id || 'nil'}"
        Rails.logger.debug "[EventsController##{action_name}] Authorization header present? #{request.headers['Authorization'].present?}"
      end

      # Plain JSON payload shaped for your specs (snake_case keys, top-level id)
      def event_payload(event, include_primary_location: false)
        payload = event.as_json

        if include_primary_location
          payload["primary_event_location"] =
            event.primary_event_location&.as_json
        end

        payload
      end

      def event_params
        params.require(:event).permit(
          :event_name,
          :event_type,
          :event_date,
          :event_time,
          :status,
          :description,
          event_speakers_performers: [],
          location: [
            :business_name,
            :business_phone,
            :location_type,
            :street_number,
            :street_name,
            :city,
            :state_province,
            :country,
            :postal_code,
            :owner_name,
            :capacity,
            :capacity_seated,
            :availability_notes,
            :has_food,
            :has_drink,
            :has_internet,
            :has_big_screen,
            :place_id,
            :location_image_attribution,
            :image_url,
            :photo_reference
          ]
        )
      end
    end
  end
end
