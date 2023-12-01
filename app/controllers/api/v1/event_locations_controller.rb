class Api::V1::EventLocationsController < ApplicationController

  before_action :set_event, only: [:index, :create]
  before_action :set_event_location, only: [:show, :update, :destroy]  


  # GET /api/v1/events/:event_id/event_locations
  def index
    @event_locations = @event.event_locations
    render json: @event_locations
  end

  # GET /api/v1/event_locations/:id
  def show
    render json: @event_location
  end

  # POST /api/v1/events/:event_id/event_locations
  def create
    EventLocation.transaction do
      @event_location = EventLocation.new(event_location_params)

      if @event_location.save
        EventLocationConnector.create!(event: @event, event_location: @event_location)
        render json: @event_location, status: :created
      else
        # Log the error for internal review
        Rails.logger.error "EventLocation creation failed: #{@event_location.errors.full_messages}, an event may have been scheduled for this location"

        # Provide a more detailed error message for the API consumer
        render json: { 
          status: 'error', 
          message: 'Failed to create event location, an event may have been scheduled for this location.', 
          errors: @event_location.errors.full_messages 
        }, status: :unprocessable_entity

        raise ActiveRecord::Rollback
      end
    end
  end

  # PATCH/PUT /api/v1/event_locations/:id
  def update
    if @event_location.update(event_location_params)
      render json: @event_location
    else
      render json: @event_location.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/event_locations/:id
  def destroy
    # Check if there are any connectors associated with this event location
    if EventLocationConnector.exists?(event_location_id: @event_location.id)
      render json: { error: "You cannot delete this location while events are scheduled to be held at this location." }, status: :unprocessable_entity
    else
      @event_location.destroy
      head :no_content
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_event_location
    @event_location = EventLocation.find(params[:id])
  end

  def event_location_params
    params.require(:event_location).permit(
      :business_name,
      :location_image,
      :phone,
      :address,
      :address_type,
      :room_suite_no,
      :floor,
      :building,
      :street_number,
      :street_predirection,
      :street_name,
      :street_postdirection,
      :street_suffix,
      :apartment_suite_number,
      :city,
      :county,
      :state_abbreviation,
      :country_code,
      :postal_code,
      :plus4_code,
      :latitude,
      :longitude,
      :time_zone
    )
  end
end