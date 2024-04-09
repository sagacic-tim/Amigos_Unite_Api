class Api::V1::EventsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors
  before_action :set_event, only: [:show, :update, :destroy]
  before_action :authenticate_amigo!, except: [:index, :show] # Assuming you have some authentication

  # GET /api/v1/events
  def index
    @events = Event.all
    render json: @events
  end

  # GET /api/v1/events/:id
  def show
    render json: @event
  end

  # POST /api/v1/events
  def create
    @event = Event.new(event_params)
    @event.lead_coordinator = current_amigo # Assuming `current_amigo` is available

    if @event.save
      # Automatically create a connector for the lead coordinator
      EventAmigoConnector.create!(event: @event, amigo: current_amigo, role: :lead_coordinator)
      render json: @event, status: :created
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
      # Note: `:event_coordinator_id` removed from permitted parameters
    )
  end
end
