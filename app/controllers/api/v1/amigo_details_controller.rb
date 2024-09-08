class Api::V1::AmigoDetailsController < ApplicationController

  before_action :authenticate_amigo!
  before_action :verify_csrf_token, only: [:create, :update, :destroy]
  before_action :set_amigo, only: [:show, :create, :update, :destroy]
  before_action :set_amigo_detail, only: [:show, :update, :destroy]

  # GET /api/v1/amigos/:amigo_id/amigo_detail
  def show
    if @amigo_detail
      render json: @amigo_detail, status: :ok
    else
      render json: { message: 'No details information found.' }, status: :ok
    end
  end

  # POST /api/v1/amigos/:amigo_id/amigo_detail
  def create
    @amigo_detail = @amigo.build_amigo_detail(amigo_detail_params)
    if @amigo_detail.save
      render json: @amigo_detail, status: :created
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/amigos/:amigo_id/amigo_detail
  def update
    if @amigo_detail.update(amigo_detail_params)
      render json: @amigo_detail, status: :ok
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/amigos/:amigo_id/amigo_detail
  def destroy
    @amigo_detail.destroy
    head :no_content
  end

  private

  def set_amigo
    @amigo = Amigo.find(params[:amigo_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Amigo not found' }, status: :not_found
  end

  def set_amigo_detail
    @amigo_detail = @amigo.amigo_detail
    # No need to render an error here; handle it in the `show` action.
  end

  def amigo_detail_params
    params.require(:amigo_detail).permit(:date_of_birth, :member_in_good_standing, :available_to_host, :willing_to_help, :willing_to_donate, :personal_bio)
  end 
end