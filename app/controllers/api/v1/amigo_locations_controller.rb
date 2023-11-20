class Api::V1::AmigoLocationsController < ApplicationController
  before_action :authenticate_amigo!
  before_action :set_amigo
  before_action :set_amigo_location, only: [:show, :update, :destroy]

  def index
    @locations = @amigo.amigo_locations
    render json: @locations
  end

  def show
    render json: @amigo_location
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
      render json: @amigo_location
    else
      render json: @amigo_location.errors, status: :unprocessable_entity
    end
  end

  def destroy
    if @amigo_location
      @amigo_location.destroy
      render json: { message: 'Location successfully deleted' }, status: :ok
    else
      render json: { error: 'Location not found' }, status: :not_found
    end
  end

  private

  def set_amigo
    @amigo = current_amigo
  end

  def set_amigo_location
    @amigo_location = @amigo.amigo_locations.find_by(id: params[:id])
  end    

  def location_params
    # your parameters here
  end
end
