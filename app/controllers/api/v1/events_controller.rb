class Api::V1::EventsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors
  before_action :set_event, only: [:show, :update, :destroy]

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

    if @event.save
      handle_event_location_association if params[:event][:event_location_id].present?
      render json: @event, status: :created
    else
      render json: @event.errors, status: :unprocessable_entity
    end
  end

# PATCH/PUT /api/v1/events/:id
def update
  if @event.update(event_params)
    # Update the event's coordinator if a new coordinator_id is provided
    if params[:event][:event_coordinator_id].present?
      new_coordinator = Amigo.find(params[:event][:event_coordinator_id])
      @event.coordinator = new_coordinator
    end

    # Update the event's location if a new event_location_id is provided
    if params[:event][:event_location_id].present?
      connector = @event.event_location_connectors.first_or_initialize
      connector.update!(event_location_id: params[:event][:event_location_id])
    elsif @event.event_location_connectors.any?
      # Handle the case where the event's location is being removed
      @event.event_location_connectors.destroy_all
    end

    render json: @event
  else
    render json: @event.errors, status: :unprocessable_entity
  end
end 

  # DELETE /api/v1/events/:id
  def destroy
    Event.transaction do
      # First, destroy any associated connectors
      @event.event_location_connectors.destroy_all

      # Then, destroy the event itself
      if @event.destroy
        head :no_content
      else
        render json: { error: @event.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: { error: e.message }, status: :unprocessable_entity
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
      :event_coordinator_id,
      event_speakers_performers: []
    )
  end
end