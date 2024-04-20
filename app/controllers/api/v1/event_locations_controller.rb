# app/controllers/api/v1/event_locations_controller.rb
class Api::V1::EventLocationsController < ApplicationController
  before_action :set_event, only: [:index], if: -> { params[:event_id].present? }
  before_action :set_event_location, only: [:show, :update, :destroy]

  # GET /events/:event_id/event_locations or /event_locations
  def index
    if @event
      @event_locations = @event.event_locations
    else
      @event_locations = EventLocation.all
    end
    render :index
  end

  # GET /api/v1/event_locations/:id
  def show
    render json: @event_location
  end

  # POST /api/v1/event_locations
  def create
    @event_location = EventLocation.new(event_location_params)

    if @event_location.save
      render json: @event_location, status: :created
    else
      render json: @event_location.errors, status: :unprocessable_entity
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
    @event_location.destroy
    head :no_content
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Event not found' }, status: :not_found
  end

  def set_event_location
    @event_location = EventLocation.find(params[:id])
  end

  def event_location_params
    params.require(:event_location).permit(
      :business_name,
      :business_phone,
      :address,
      :floor,
      :street_number,
      :street_name,
      :room_no,
      :apartment_suite_number,
      :city_sublocality,
      :city,
      :state_province_subdivision,
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