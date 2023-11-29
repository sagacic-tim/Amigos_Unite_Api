class Api::V1::EventsController < ApplicationController
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
    Event.transaction do
      @event = Event.new(event_params)
      if @event.save
        if params[:event][:event_location_id].present?
          EventLocationConnector.create!(event: @event, event_location_id: params[:event][:event_location_id])
        end
        render json: @event, status: :created
      else
        render json: @event.errors, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  end

  # PATCH/PUT /api/v1/events/:id
  def update
    if @event.update(event_params)
      if params[:event][:event_location_id].present?
        connector = @event.event_location_connectors.first_or_initialize
        connector.update!(event_location_id: params[:event][:event_location_id])
      end
      render json: @event
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
      :event_coordinator_id,
      event_speakers_performers: []
    )
  end
end