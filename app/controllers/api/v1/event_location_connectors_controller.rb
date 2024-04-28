# app/controllers/api/v1/event_location_connectors_controller.rb
class Api::V1::EventLocationConnectorsController < ApplicationController
  before_action :set_event, only: [:create, :destroy]

  # GET /api/v1/events/:event_id/event_location_connectors
  def index
    begin
      @event = Event.find(params[:event_id])
      @event_location_connectors = @event.event_location_connectors.includes(:event_location)
      render :index
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Event not found' }, status: :not_found
    end
  end

  # GET /api/v1/events/:event_id/event_location_connectors/:id
  def show
    begin
      @event_location_connector = EventLocationConnector.includes(:event, :event_location).find(params[:id])
      
      # Ensure the connector belongs to the specified event
      if @event_location_connector.event_id != params[:event_id].to_i
        render json: { error: "Connector does not belong to the specified event" }, status: :forbidden
      else
        render :show
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Event Location Connector not found' }, status: :not_found
    end
  end

  # POST /api/v1/events/:event_id/event_location_connectors
  def create
    @event_location_connector = EventLocationConnector.find_or_initialize_by(
      event_id: params[:event_id],
      event_location_id: params[:event_location_id]
    )

    if @event_location_connector.new_record?
      if @event_location_connector.save
        @message = 'Location added to event successfully.'
        render :create, status: :created
      else
        @errors = @event_location_connector.errors.full_messages
        render :create, status: :unprocessable_entity
      end
    else
      @message = 'Location already connected to this event'
      render :create, status: :ok
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # PATCH/PUT /api/v1/events/:event_id/event_location_connectors/:id
  def update
    @event_location_connector = EventLocationConnector.find_by(id: params[:id])

    if @event_location_connector.nil?
      render json: { error: "Event location connector not found" }, status: :not_found
      return
    elsif @event_location_connector.event_id != params[:event_id].to_i
      render json: { error: "This connector does not belong to the specified event" }, status: :forbidden
      return
    end

    if @event_location_connector.update(event_location_connector_params)
      render :update  # Assumes there's a corresponding jbuilder view or similar to format the response
    else
      render json: @event_location_connector.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:event_id/event_location_connectors/:id
  def destroy
    @event_location_connector = EventLocationConnector.find_by(event_id: params[:event_id], id: params[:id])
    Rails.logger.debug "Attempting to destroy EventLocationConnector: #{@event_location_connector}"

    if @event_location_connector
      if @event_location_connector.destroy
        Rails.logger.debug "Deletion successful"
        render json: { message: 'Event Location Connector successfully deleted' }, status: :ok
      else
        Rails.logger.debug "Deletion failed: #{connector.errors.full_messages.join(", ")}"
        render json: { error: 'Failed to delete: ' + @event_location_connector.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    else
      Rails.logger.debug "Connector not found"
      render json: { error: 'Event Location Connector not found or does not belong to the specified event.' }, status: :not_found
    end
  end

  # DELETE /api/v1/events/:event_id/remove_location/:id
  # def remove_location
  #   @event_location_connector = EventLocationConnector.find_by(event_id: params[:event_id], id: params[:id])
  #   if @event_location_connector&.destroy
  #     render :remove_location, status: :ok
  #   else
  #     @error = 'Failed to disconnect location from event'
  #     render :remove_location, status: :unprocessable_entity
  #   end
  # end

  private

  def set_event
    @event = Event.find_by(id: params[:event_id])
    render json: { error: 'Event not found' }, status: :not_found unless @event
  end

  def event_location_connector_params
    params.require(:event_location_connector).permit(:event_location_id)
  end  
end