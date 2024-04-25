class Api::V1::AmigosController < ApplicationController
  before_action :authenticate_amigo!, only: [:show, :update, :destroy]
  before_action :set_amigo, only: [:show, :update, :destroy]
  before_action :authorize_amigo!, only: [:destroy]
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :current_amigo

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
    @amigo = Amigo.find_by(id: params[:id])
    if @amigo.nil?
      render json: { error: "Amigo not found" }, status: :not_found
    elsif @amigo.destroy
      render :destroy, status: :ok  # Use JBuilder to render the success response with status 200
    else
      render json: { errors: @amigo.errors.full_messages }, status: :unprocessable_entity
    end
  end  

  private

  def set_amigo
    @amigo = Amigo.find_by(id: params[:id])
    unless @amigo
      render json: { error: "Amigo with ID #{params[:id]} not found" }, status: :not_found
    end
  end  

  def authorize_amigo!
    unless current_amigo.can_manage?(@amigo)
      render json: { error: 'You are not authorized to perform this action' }, status: :unauthorized
    end
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