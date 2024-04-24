class Api::V1::AmigoDetailsController < ApplicationController
  before_action :set_amigo
  before_action :set_amigo_detail, only: [:show, :update, :destroy]

  # GET /api/v1/amigos/:amigo_id/amigo_details
  def index
    # Assuming the association is one-to-many
    @amigo_details = @amigo.amigo_details
    # The view app/views/api/v1/amigo_details/index.json.jbuilder will handle the response formatting
  end
  
  # GET /api/v1/amigos/:amigo_id/amigo_detail
  def show
    @amigo_detail = @amigo.amigo_detail
    # Assumes show.json.jbuilder renders @amigo_detail
  end

  # POST /api/v1/amigos/:amigo_id/amigo_detail
  def create
    @amigo_detail = @amigo.build_amigo_detail(amigo_detail_params)
    if @amigo_detail.save
      render :create, status: :created
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end
  
  # PATCH/PUT /api/v1/amigos/:amigo_id/amigo_detail
  def update
    if unchanged_attributes?(@amigo_detail, amigo_detail_params)
      render json: { message: "No changes detected." }, status: :ok
    elsif @amigo_detail.update(amigo_detail_params)
      render :update
    else
      render json: @amigo_detail.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/amigos/:amigo_id/amigo_detail
  def destroy
    if @amigo_detail.destroy
      # This will use the app/views/api/v1/amigo_details/destroy.json.jbuilder view to render the JSON
      render :destroy, status: :ok
    else
      # Direct JSON rendering for errors remains appropriate as it is typically straightforward
      render json: { errors: @amigo_detail.errors.full_messages }, status: :unprocessable_entity
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