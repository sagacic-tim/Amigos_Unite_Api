class Api::V1::EventLocationConnectorsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors
  
  before_action :set_event_location_connector, only: [:show, :update, :destroy]

  # GET /api/v1/event_location_connectors/:id
  def show
    render json: @event_location_connector
  end

  # POST /api/v1/event_location_connectors
  def create
    @event_location_connector = EventLocationConnector.new(event_location_connector_params)
    if @event_location_connector.save
      render json: @event_location_connector, status: :created
    else
      render json: @event_location_connector.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/event_location_connectors/:id
  def update
    if @event_location_connector.update(event_location_connector_params)
      render json: @event_location_connector
    else
      render json: @event_location_connector.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/event_location_connectors/:id
  def destroy
    @event_location_connector.destroy
    head :no_content
  end

  private

  def set_event_location_connector
    @event_location_connector = EventLocationConnector.find(params[:id])
  end

  def event_location_connector_params
    params.require(:event_location_connector).permit(:event_id, :event_location_id)
  end
end
