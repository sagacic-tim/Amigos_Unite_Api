class Api::V1::EventsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors
  before_action :set_event, only: [:show, :update, :destroy]
  before_action :authenticate_amigo!, except: [:index, :show] # Assuming you have some authentication
  before_action :debug_authentication

  # GET /api/v1/events
  def index
    @events = Event.all
    render json: @events
  end

  # GET /api/v1/events/:id
  def show
    render json: @event
  end

  def create
    Rails.logger.info "Received params: #{params.inspect}"
    @event = Event.new(event_params)
    @event.lead_coordinator = current_amigo # Set the currently logged-in amigo as the lead coordinator.
    Rails.logger.info "Event to be saved: #{@event.attributes}"

    if @event.save
      # Create a connector for the lead coordinator
      EventAmigoConnector.create!(event: @event, amigo: current_amigo, role: 'lead_coordinator')
      render :create, status: :created # Assuming you have a corresponding jbuilder view for `create`
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/events/:id
  def update
    if params[:new_lead_coordinator_id].present?
      @event.lead_coordinator_id = params[:new_lead_coordinator_id]
    end
  
    if @event.save
      render json: @event, status: :ok
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:id
  def destroy
    @event.destroy
    head :no_content
  end

  private

  def debug_authentication
    Rails.logger.info "Current User: #{current_amigo.inspect}"
    Rails.logger.info "Authorization Header: #{request.headers['Authorization']}"
  end

  def set_event
    @event = Event.find(params[:id])
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
