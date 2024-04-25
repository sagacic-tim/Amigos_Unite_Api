# app/controllers/api/v1/event_location_connectors_controller.rb
class Api::V1::EventLocationConnectorsController < ApplicationController

  # GET /api/v1/events/:event_id/event_location_connectors
  def index
    @event = Event.find(params[:event_id])
    @event_location_connectors = @event.event_location_connectors
    render :index
  end

  # GET /api/v1/events/:event_id/event_location_connectors/:id
  def show
    @event_location_connector = EventLocationConnector.find(params[:id])
    render :show
  end
  
  # POST /api/v1/events/:event_id/event_location_connectors
  def create
    @event_location_connector = EventLocationConnector.new(event_location_connector_params)
    if @event_location_connector.save
      # Uses JBuilder for successful creation
      render :create, status: :created
    else
      # Directly renders JSON in case of errors
      render json: { errors: @event_location_connector.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/events/:event_id/event_location_connectors/:id
  def update
    @event_location_connector = EventLocationConnector.find(params[:id])
    if @event_location_connector.update(event_location_connector_params)
      render :update
    else
      render json: @event_location_connector.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:event_id/event_location_connectors/:id
  def destroy
    @event_location_connector = EventLocationConnector.find(params[:id])
    @event_location_connector.destroy
    render json: { message: 'Event Location Connector successfully deleted' }, status: :ok
  end

  private

  def event_location_connector_params
    params.require(:event_location_connector).permit(
      :event_id,
      :event_location_id
    )
end