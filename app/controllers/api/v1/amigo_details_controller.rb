class Api::V1::AmigoDetailsController < ApplicationController
  before_action :set_amigo
  before_action :set_amigo_detail, only: [:show, :update, :destroy]

  # GET /api/v1/amigos/:amigo_id/amigo_detail
  def show
    render json: @amigo_detail
  end

  # POST /api/v1/amigos/:amigo_id/amigo_detail
  def create
    @amigo_detail = @amigo.build_amigo_detail(amigo_detail_params)
    Rails.logger.debug { "Params after permitting: #{amigo_detail_params.inspect}" }  
    if @amigo_detail.save
      render json: @amigo_detail, status: :created
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/amigos/:amigo_id/amigo_detail
  def update
    @amigo_detail = @amigo.amigo_detail
    
    # Check if attributes have changed
    if unchanged_attributes?(@amigo_detail, amigo_detail_params)
      render json: { message: "So sorry, but nothing changed, try again when you decide to change something!" }, status: :ok
    elsif @amigo_detail.update(amigo_detail_params)
      # Convert to JSON string for logging if needed
      json_output = @amigo_detail.as_json # Using as_json for more control over the output
      Rails.logger.debug { "Updated amigo detail: #{json_output.inspect}" }

      # Respond to client with the updated amigo detail
      render json: json_output, status: :ok
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/amigos/:amigo_id/amigo_detail
  def destroy
    if @amigo_detail.nil?
      render json: { error: 'Amigo detail not found' }, status: :not_found
      return
    end
  
    begin
      @amigo_detail.destroy!
      render json: { message: 'Amigo detail successfully deleted' }, status: :ok
    rescue ActiveRecord::RecordNotDestroyed => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end
  end  
  
  private

  def set_amigo
    @amigo = Amigo.find(params[:amigo_id])
  end

  def set_amigo_detail
    @amigo_detail = @amigo.amigo_detail
  end

# Checks if the attributes of the model have changed compared to the new parameters
def unchanged_attributes?(model, new_attributes)
  new_attributes = new_attributes.to_h # Convert Parameters to a hash
  new_attributes.none? { |attr, value| model.send(attr) != value }
end


  def amigo_detail_params
    params.require(:amigo_detail).permit(
      :date_of_birth,
      :member_in_good_standing,
      :available_to_host,
      :willing_to_help,
      :willing_to_donate,
      :personal_bio
    )
  end
end