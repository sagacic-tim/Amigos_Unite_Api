# app/controllers/api/v1/amigo_details_controller.rb
class Api::V1::AmigoDetailsController < ApplicationController
  before_action :authenticate_amigo!
  before_action :verify_csrf_token, only: [:create, :update, :destroy]
  before_action :set_amigo
  before_action :set_amigo_detail, only: [:show, :update, :destroy]

  # GET /api/v1/amigos/:amigo_id/amigo_detail
  def show
    if @amigo_detail
      render json: @amigo_detail, status: :ok
    else
      # 404 helps the frontend know it should POST to create
      render json: { error: 'No details found' }, status: :not_found
    end
  end

  # POST /api/v1/amigos/:amigo_id/amigo_detail
  def create
    if @amigo_detail
      # If it exists already, treat as update (or you can return 409)
      if @amigo_detail.update(amigo_detail_params)
        render json: @amigo_detail, status: :ok
      else
        render json: @amigo_detail.errors, status: :unprocessable_entity
      end
      return
    end

    detail = @amigo.build_amigo_detail(amigo_detail_params)
    if detail.save
      render json: detail, status: :created
    else
      render json: detail.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/amigos/:amigo_id/amigo_detail
  def update
    # ←—— upsert: build if it doesn't exist yet
    @amigo_detail ||= @amigo.build_amigo_detail

    if @amigo_detail.update(amigo_detail_params)
      # If we just created it, :created; otherwise :ok
      status = @amigo_detail.previous_changes.key?('id') ? :created : :ok
      render json: @amigo_detail, status: status
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/amigos/:amigo_id/amigo_detail
  def destroy
    if @amigo_detail
      @amigo_detail.destroy
      head :no_content
    else
      render json: { error: 'No details found' }, status: :not_found
    end
  end

  private

  def set_amigo
    @amigo = Amigo.find_by(id: params[:amigo_id])
    unless @amigo
      render json: { error: 'Amigo not found' }, status: :not_found and return
    end
  end

  def set_amigo_detail
    @amigo_detail = @amigo.amigo_detail
  end

  def amigo_detail_params
    # :message from earlier responses will be dropped here automatically
    permitted = params.require(:amigo_detail).permit(
      :date_of_birth,
      :member_in_good_standing,
      :available_to_host,
      :willing_to_help,
      :willing_to_donate,
      :personal_bio
    )
    # Treat blank DOB as nil so validations allow "unset"
    if permitted.key?(:date_of_birth) && permitted[:date_of_birth].respond_to?(:strip) && permitted[:date_of_birth].strip == ""
      permitted[:date_of_birth] = nil
    end
    permitted
  end
end
