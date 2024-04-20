class Api::V1::AmigosController < ApplicationController
  before_action :authenticate_amigo!, only: [:show, :update, :destroy]
  before_action :set_amigo, only: [:show, :update, :destroy]

  # Get all amigos
  def index
    @amigos = Amigo.includes(event_amigo_connectors: :event).all
    render :index, status: :ok
  end
  

  # GET /amigos/1
  def show
    render json: @amigo, include: { event_amigo_connectors: { include: :event } }
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
