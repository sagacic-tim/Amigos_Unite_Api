# app/controllers/api/v1/events_controller.rb
module Api
  module V1
    class EventsController < ApplicationController
      include ErrorHandling

      before_action :authenticate_amigo!, except: [:index, :show, :mission_index]
      before_action :debug_authentication, if: -> { Rails.env.development? }
      before_action :verify_csrf_token, only: [:create, :update, :destroy]
      before_action :set_event, only: [:show, :update, :destroy]

      rescue_from ActiveRecord::RecordNotFound, with: :handle_standard_error
      rescue_from StandardError,               with: :handle_standard_error

      # GET /api/v1/events
      def index
        events = Event.all
        render json: events,
               each_serializer: EventSerializer,
               status: :ok
      rescue ActiveRecord::ConnectionNotEstablished
        render json: { error: "Database connection error." },
               status: :service_unavailable
      end

      # GET /api/v1/events/:id
      def show
        render json: @event,
               serializer: EventSerializer,
               include: [:primary_event_location],
               status: :ok
      end

      # POST /api/v1/events
      def create
        policy = EventPolicy.new(current_amigo, nil)
        return render json: { error: "Unauthorized" }, status: :unauthorized unless policy.create?

        event = Events::CreateEvent.new.call(
          creator: current_amigo,
          attrs:   event_params
        )

        render json: event,
               serializer: EventSerializer,
               include: [:primary_event_location],
               status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          errors: event&.errors&.full_messages || [e.message]
        }, status: :unprocessable_entity
      end

      # PATCH/PUT /api/v1/events/:id
      def update
        authorize_event!(@event, :update?)

        Event.transaction do
          # 1) Optional lead coordinator swap
          if params[:new_lead_coordinator_id].present?
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
          Rails.logger.debug "[EventsController#update] RAW params: #{params.to_unsafe_h.inspect}"
          raw_params     = event_params.to_h.deep_dup
          location_attrs = raw_params.delete("location") || raw_params.delete(:location)
          Rails.logger.debug "[EventsController#update] event core: #{raw_params.inspect}"
          Rails.logger.debug "[EventsController#update] location_attrs: #{location_attrs.inspect}"

          # 3) Update event core fields
          @event.update!(raw_params)

          # 4) Upsert primary location (create or update + connector + image)
          if location_attrs.present?
            Events::UpsertPrimaryLocation.new.call(
              event:     @event,
              raw_attrs: location_attrs
            )
          end
        end

        render json: @event,
               serializer: EventSerializer,
               include: [:primary_event_location],
               status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages },
               status: :unprocessable_entity
      end

      # DELETE /api/v1/events/:id
      def destroy
        authorize_event!(@event, :destroy?)

        if @event.destroy
          render json: { message: "Event successfully deleted." }, status: :ok
        else
          render json: { error: @event.errors.full_messages.to_sentence },
                 status: :unprocessable_entity
        end
      end

      # GET /api/v1/events/my_events
      # Return only events the current_amigo manages (lead or assistant coordinator).
      def my_events
        authenticate_amigo!

        # Convert enum names to their integer values
        coordinator_roles =
          EventAmigoConnector.roles.values_at("lead_coordinator", "assistant_coordinator")
        # => e.g. [2, 1] depending on your enum definition

        events = Event
          .left_outer_joins(:event_amigo_connectors) # more forgiving than INNER JOIN
          .where(
            "events.lead_coordinator_id = :id OR " \
            "(event_amigo_connectors.amigo_id = :id AND event_amigo_connectors.role IN (:roles))",
            id: current_amigo.id,
            roles: coordinator_roles
          )
          .distinct

        render json: events, each_serializer: EventSerializer, status: :ok
      end

      # GET /api/v1/events/mission
      def mission_index
        render "api/v1/events/mission_index"
      end

      private

      def debug_authentication
        if Rails.env.development?
          Rails.logger.debug "[EventsController##{action_name}] current_amigo: #{current_amigo&.id || 'nil'}"
          Rails.logger.debug "[EventsController##{action_name}] Authorization header present? #{request.headers['Authorization'].present?}"
        end
      end

      def set_event
        @event = Event.find(params[:id])
      end

      def handle_standard_error(e)
        Rails.logger.error "[EventsController#{action_name}] #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n") if Rails.env.development?

        if e.is_a?(ActiveRecord::RecordNotFound) && action_name == "show"
          render json: { error: "Event with ID #{params[:id]} does not exist." },
                 status: :not_found
        else
          message =
            if Rails.env.development?
              e.message
            else
              "An unexpected error occurred. Please try again later."
            end

          render json: { error: message }, status: :internal_server_error
        end
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

      def authorize_event!(record, action)
        policy = EventPolicy.new(current_amigo, record)
        ok     = policy.public_send(action)
        return if ok

        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end
end
