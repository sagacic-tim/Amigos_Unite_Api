class Api::V1::AmigoLocationsController < ApplicationController
  before_action :authenticate_amigo!
  before_action :set_amigo
  before_action :set_amigo_location, only: [:show, :update, :destroy]

  # GET /amigos/:amigo_id/amigo_locations
  def index
    @locations = @amigo.locations
    render json: @locations
  end

  # GET /amigos/:amigo_id/amigo_locations/1
  def show
    render json: @location
  end

  # POST /amigos/:amigo_id/amigo_locations
  def create
    @location = @amigo.locations.build(location_params)

    if @location.save
      render json: @location, status: :created
    else
      render json: @location.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /amigos/:amigo_id/amigo_locations/1
  def update
    if @location.update(location_params)
      render json: @location
    else
      render json: @location.errors, status: :unprocessable_entity
    end
  end

  # DELETE /amigos/:amigo_id/amigo_locations/1
  def destroy
    @location.destroy
    head :no_content
  end

  private
    def set_amigo
      @amigo = current_amigo
    end

    def set_amigo_location
      @amigo_location = @amigo.amigo_locations.find(params[:id])
    end    

    def location_params
      params.require(:location).permit(
        :address,
        :address_type,
        :floor,
        :building,
        :street_number,
        :street_predirection,
        :street_name,
        :street_suffix,
        :street_postdirection,
        :apartment_number,
        :city,
        :county,
        :state_abbreviation,
        :country_code,
        :postal_code,
        :plus4_code,
        :latitude,
        :longitude,
        :time_zone,
        :congressional_district
      )
    end
end
