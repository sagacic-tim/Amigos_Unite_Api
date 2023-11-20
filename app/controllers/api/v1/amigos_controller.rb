class Api::V1::AmigosController < ApplicationController
  before_action :authenticate_amigo!, only: [:show, :update, :destroy]
  before_action :set_amigo, only: [:show, :update, :destroy]

  # GET /amigos
  def index
    @amigos = Amigo.all
    render :index, formats: :json, status: :ok
  end  

  # GET /amigos/1
  def show
    render json: @amigo
  end

  # POST /amigos
  def create
    @amigo = Amigo.new(amigo_params)
  
    if @amigo.save
      response_hash = {
        amigo: @amigo
      }
  
      response_hash[:avatar_url] = url_for(@amigo.avatar) if @amigo.avatar.attached?
  
      render json: response_hash, status: :created
    else
      render json: @amigo.errors, status: :unprocessable_entity
    end
  end  

  # PATCH/PUT /amigos/1
  def update
    if @amigo.update(amigo_params)
      @amigo.avatar.attach(params[:avatar]) if params[:avatar].present?

      render json: {
        amigo: @amigo.as_json(include: { avatar_attachment: { only: :id }}),
        avatar_url: @amigo.avatar.attached? ? url_for(@amigo.avatar) : nil
      }
    else
      render json: @amigo.errors, status: :unprocessable_entity
    end
  end

  # DELETE /amigos/1
  # def destroy
  #   @amigo.destroy
  #   head :no_content
  # end

  def destroy
    if @amigo.destroy
      render json: { message: 'Amigo successfully deleted.' }, status: :ok
    else
      render json: { errors: @amigo.errors.full_messages }, status: :unprocessable_entity
    end
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
        :avatar)
    end
end