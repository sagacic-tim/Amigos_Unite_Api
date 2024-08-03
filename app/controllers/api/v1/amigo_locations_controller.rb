class Api::V1::AmigoLocationsController < ApplicationController
  include ErrorHandling  # For handling common ActiveRecord errors

  before_action :authenticate_amigo!
  before_action :set_amigo, only: [:index], if: -> { params[:amigo_id].present? }
  before_action :set_amigo_location, only: [:show, :update, :destroy]

  def index
    if @amigo
      @amigo_locations = @amigo.amigo_locations
    else
      @amigo_locations = AmigoLocation.all
    end
    render json: @amigo_locations, status: :ok
  end

  def show
    if @amigo_location
      render json: @amigo_location, status: :ok
    else
      render json: { error: 'Location not found' }, status: :not_found
    end
  end  

  def create
    @amigo_location = @amigo.amigo_locations.build(location_params)
    if @amigo_location.save
      render json: @amigo_location, status: :created
    else
      render json: @amigo_location.errors, status: :unprocessable_entity
    end
  end

  def update
    if @amigo_location.update(location_params)
      render json: @amigo_location, status: :ok
    else
      render json: @amigo_location.errors, status: :unprocessable_entity
    end
  end  

  def destroy
    if @amigo_location.destroy
      render json: { message: 'Location deleted successfully' }, status: :ok
    else
      render json: { error: 'Location not found' }, status: :not_found
    end
  end

  private

  def set_amigo
    @amigo = Amigo.find(params[:amigo_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Amigo not found' }, status: :not_found
  end

  def set_amigo_location
    @amigo_location = @amigo.amigo_locations.find_by(id: params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Location not found' }, status: :not_found
  end    

  def location_params
    params.require(:amigo_location).permit(:address, :floor, :street_number, :street_name, :room_no, :apartment_suite_number, :city_sublocality, :city, :state_province_subdivision, :state_province, :state_province_short, :country, :country_short, :postal_code, :postal_code_suffix, :post_box, :latitude, :longitude, :time_zone)
  end  
end