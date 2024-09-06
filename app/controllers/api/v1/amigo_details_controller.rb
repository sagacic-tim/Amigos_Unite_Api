class Api::V1::AmigoDetailsController < ApplicationController

  before_action :authenticate_amigo!
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

  def authenticate_amigo!
    # Decode the signed cookie to extract the JWT token
    token = cookies.signed[:jwt] || cookies.encrypted[:jwt]
    
    Rails.logger.debug { "Decoded JWT Token from cookie: #{token.inspect}" }
    
    # Now, decode the JWT token itself
    decoded_token = JsonWebToken.decode(token)
    Rails.logger.debug { "Decoded Token: #{decoded_token.inspect}" }
    
    amigo_id = decoded_token['sub']
    Rails.logger.debug { "Amigo ID from token: #{amigo_id}" }
    
    @current_amigo = Amigo.find(amigo_id)
  rescue JWT::DecodeError => e
    Rails.logger.error { "JWT Decode Error: #{e.message}" }
    render json: { error: 'Unauthorized' }, status: :unauthorized
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error { "Amigo not found for ID: #{amigo_id}" }
    render json: { error: 'Amigo not found' }, status: :unauthorized
  end  
end