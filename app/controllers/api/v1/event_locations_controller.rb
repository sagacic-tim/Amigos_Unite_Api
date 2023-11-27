class Api::V1::EventLocationsController < ApplicationController
  before_action :set_event
  before_action :set_event_location, only: [:show, :update, :destroy]

  # GET /api/v1/events/:event_id/event_locations
  def index
    @event_locations = @event.event_location
    render json: @event_locations
  end

  # GET /api/v1/events/:event_id/event_locations/:id
  def show
    @event_location = EventLocation.find(params[:id])
  end

  # POST /api/v1/events/:event_id/event_locations

  def create
    @event_location = EventLocation.new(event_location_params)

    if @event_location.save
      ProcessImageJob.perform_later(@event_location.id)
      render json: @event_location, status: :created
    else
      render json: @event_location.errors, status: :unprocessable_entity
    end
  end
  

  # PATCH/PUT /api/v1/events/:event_id/event_locations/:id
  def update
    if @event_location.update(event_location_params)
      render json: @event_location
    else
      render json: @event_location.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/events/:event_id/event_locations/:id
  def destroy
    @event_location.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_event_location
    @event_location = @event.event_location.find(params[:id])
  end

  def event_location_params
    params.require(:event_location).permit(
      :other, :attributes, :location_image,
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