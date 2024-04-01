# app/controllers/api/v1/event_locations_controller.rb

class Api::V1::EventLocationsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors

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
    @event_location = @event.event_locations.build(event_location_params)

    if @event_location.save
      EventLocationConnector.create!(event: @event, event_location: @event_location)
      render json: @event_location, status: :created
    else
      # Custom error logic for specific create action scenarios
      render json: { 
        status: 'error', 
        message: 'Failed to create event location, an event may have been scheduled for this location.', 
        errors: @event_location.errors.full_messages 
      }, status: :unprocessable_entity
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
    params.require(:amigo_location).permit(
      :business_name,
      :business_phone,
      :address,
      :floor,
      :street_number,
      :street_number,
      :street_name,
      :room_no,
      :apartment_suite_number,
      :city_sublocality,
      :city,
      :state_province_subdivision,
      :state_abbreviation,
      :state_province,
      :state_province_short,
      :country,
      :country_short,
      :postal_code,
      :postal_code_suffix,
      :post_box,
      :latitude,
      :longitude,
      :time_zone
    )
  end
end