# app/controllers/api/v1/events_controller.rb
class Api::V1::EventsController < ApplicationController
  include ErrorHandling  # your shared error concern

  # Public reads: index, show, mission_index
  # All other actions require a valid JWT (protected routes).
  before_action :authenticate_amigo!, except: [:index, :show, :mission_index]

  # Helpful, but noisy in production – restrict to development.
  before_action :debug_authentication, if: -> { Rails.env.development? }

  # Tighten writes: require CSRF token on all mutating actions.
  before_action :verify_csrf_token, only: [:create, :update, :destroy]

  before_action :set_event, only: [:show, :update, :destroy]

  # Central error handling for unexpected failures.
  rescue_from ActiveRecord::RecordNotFound, with: :handle_standard_error
  rescue_from StandardError,               with: :handle_standard_error

  # GET /api/v1/events
  def index
    @events = Event.all
    render :index
  rescue ActiveRecord::ConnectionNotEstablished
    # Special-case DB failures, let rescue_from handle everything else.
    render json: { error: "Database connection error." }, status: :service_unavailable
  end

  # GET /api/v1/events/:id
  def show
    render :show  # @event set by set_event
  end

  # POST /api/v1/events
  def create
    # Use your EventPolicy in "class-level" mode; record is nil.
    policy = EventPolicy.new(current_amigo, nil)
    return render json: { error: "Unauthorized" }, status: :unauthorized unless policy.create?

    permitted = event_params 

    event = Events::CreateEvent.new.call(
      creator: current_amigo,
      attrs:   permitted
    )

    render json: {
      id:                  event.id,
      event_name:          event.event_name,
      event_date:          event.event_date,
      event_time:          event.event_time,
      status:              event.status,            # enum string ("planning", etc.)
      lead_coordinator_id: event.lead_coordinator_id
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      errors: event&.errors&.full_messages || [e.message]
    }, status: :unprocessable_entity
  end

  # PATCH/PUT /api/v1/events/:id
  def update
    authorize_event!(@event, :update?)

    Event.transaction do
      if params[:new_lead_coordinator_id].present?
        new_id = params[:new_lead_coordinator_id].to_i

        # Remove any existing lead row that isn't the new one, then upsert the new lead
        @event.event_amigo_connectors.lead_coordinator.where.not(amigo_id: new_id).delete_all
        @event.event_amigo_connectors
              .find_or_initialize_by(amigo_id: new_id)
              .update!(role: :lead_coordinator)

        @event.update!(lead_coordinator_id: new_id)
      end

      @event.update!(event_params)
    end

    render :update
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity
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

  # GET /api/v1/events/mission
  def mission_index
    render "api/v1/events/mission_index"
  end

  private

  def debug_authentication
    Rails.logger.debug "[EventsController##{action_name}] current_amigo: #{current_amigo&.id || 'nil'}" if Rails.env.development?
    Rails.logger.debug "[EventsController##{action_name}] Authorization header present? #{request.headers['Authorization'].present?}" if Rails.env.development?
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def handle_standard_error(e)
    # Log details for you (server-side)
    Rails.logger.error "[EventsController#{action_name}] #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.development?

    if e.is_a?(ActiveRecord::RecordNotFound) && action_name == "show"
      render json: { error: "Event with ID #{params[:id]} does not exist." },
             status: :not_found
    else
      # Generic message to the client, detailed message only in logs
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
      :status,                # FE sends "status": "planning"
      :description,
      event_speakers_performers: []
    )
  end

  # Minimal policy invoker without bringing in full Pundit integration
  def authorize_event!(record, action)
    policy = EventPolicy.new(current_amigo, record)
    ok     = policy.public_send(action)
    return if ok

    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
