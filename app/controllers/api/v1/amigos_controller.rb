class Api::V1::AmigosController < ApplicationController
  before_action :authenticate_amigo!, only: [:show, :update, :destroy]
  before_action :set_amigo, only: [:show, :update, :destroy]

  # Get all amigos and their avatars
  def index
    @amigos = Amigo.all.includes(:avatar_attachment) # includes avatar attachment to avoid N+1 queries
    render :index, status: :ok
  end
  
  # GET /amigos/1
  def show
    # By default, this will look for `show.json.jbuilder` in the `views/api/v1/amigos` directory
    render :show
  end

  # POST /amigos
  def create
    @amigo = Amigo.new(amigo_params.except(:avatar))
    
    if params[:amigo][:avatar]
      @amigo.attach_avatar_by_identifier(params[:amigo][:avatar])
    end
  
    if @amigo.save
      render :create
    else
      render json: @amigo.errors, status: :unprocessable_entity
    end
  end  

  # PATCH/PUT /amigos/1
  def update
    if @amigo.update(amigo_params)
      render :update
    else
      render json: @amigo.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @amigo.destroy
    head :no_content
  end

  private

  def set_amigo
    @amigo = Amigo.find(params[:id])
  end

  def amigo_params
    params.require(:amigo).permit(
      :first_name,
      :last_name,
      :user_name,
      :email,
      :password,
      :secondary_email,
      :phone_1,
      :phone_2,
    )
  end
end