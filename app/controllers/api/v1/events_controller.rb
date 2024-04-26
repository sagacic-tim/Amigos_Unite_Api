class Api::V1::EventsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors
  before_action :authenticate_current_user!, except: [:index, :show, :mission_index]
  before_action :debug_authentication
  before_action :set_event, only: [:show, :update, :destroy]
  rescue_from StandardError, with: :handle_standard_error

  # GET /api/v1/events
  def index
    @events = Event.all
    render :index
  rescue ActiveRecord::ConnectionNotEstablished => e
    render json: { error: 'Database connection error.' }, status: :service_unavailable
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # GET /api/v1/events/:id 
  def show
    if @event
      render :show
    else
      render json: { error: 'Event not found' }, status: :not_found
    end
  end  
  
  # POST /api/v1/events
  def create
    @event = Event.new(event_params)
    @event.lead_coordinator = current_amigo
    if @event.save
      EventAmigoConnector.create!(event: @event, amigo: current_amigo, role: 'lead_coordinator')
      render :create, status: :created
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end

  # PATCH/PUT /api/v1/events/:id
  def update
    if params[:new_lead_coordinator_id].present?
      @event.lead_coordinator_id = params[:new_lead_coordinator_id]
    end
  
    if @event.update(event_params)
      render :update
    else
      render json: { error: @event.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # DELETE /api/v1/events/:id
  def destroy
    @event = Event.find(params[:id])
    if @event.destroy
      render json: { message: "Event successfully deleted." }, status: :ok
    else
      render json: { error: @event.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: "Event not found." }, status: :not_found
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end   

  # GET /api/v1/events/mission
  def mission_index
    # This is a hypothetical action; you'll need to define what data to show
    render 'api/v1/events/mission_index'
  end

  private

  def debug_authentication
    Rails.logger.info "Current User: #{current_amigo.inspect}"
    Rails.logger.info "Authorization Header: #{request.headers['Authorization']}"
  end

  def set_event
    @event = Event.find(params[:id])
  end  

  def handle_standard_error(e)
    render json: { error: 'An unexpected error occurred.' }, status: :internal_server_error
  end

  def event_params
    params.require(:event).permit(
      :event_name,
      :event_type,
      :event_date,
      :event_time,
      event_speakers_performers: []
    )
  end
end