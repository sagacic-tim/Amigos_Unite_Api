# app/controllers/api/v1/event_location_connectors_controller.rb
class Api::V1::EventLocationConnectorsController < ApplicationController

  # POST /api/v1/events/:event_id/event_location_connectors
  def create
    @event_location_connector = EventLocationConnector.new(event_location_connector_params)
    if @event_location_connector.save
      render json: @event_location_connector, status: :created
    else
      render json: @event_location_connector.errors, status: :unprocessable_entity
    end
  end

  private

  def event_location_connector_params
    params.require(:event_location_connector).permit(
      :event_id,
      :event_location_id
    )
end