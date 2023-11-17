class Api::V1::AmigoDetailsController < ApplicationController
  before_action :set_amigo_detail, only: [:show, :update, :destroy]

  # GET /api/v1/amigo_details/1
  def show
    render json: @amigo_detail
  end

  # POST /api/v1/amigo_details
  def create
    @amigo_detail = AmigoDetail.new(amigo_details_params)

    if @amigo_detail.save
      render json: @amigo_detail, status: :created
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/amigo_details/1
  def update
    if @amigo_detail.update(amigo_details_params)
      render json: @amigo_detail
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/amigo_details/1
  def destroy
    @amigo_detail.destroy
    head :no_content
  end

  private

  def set_amigo_detail
    @amigo_detail = AmigoDetail.find(params[:id])
  end

  def amigo_details_params
    params.require(:amigo_detail).permit(:date_of_birth, :member_in_good_standing, :available_to_host, :willing_to_help, :willing_to_donate, :personal_bio, :amigo_id)
  end
end