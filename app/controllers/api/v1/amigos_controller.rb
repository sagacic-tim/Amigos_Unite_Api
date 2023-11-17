class Api::V1::AmigosController < ApplicationController
  before_action :authenticate_amigo!, only: [:show, :update, :destroy]
  before_action :set_amigo, only: [:show, :update, :destroy]

  # GET /amigos
  def index
    @amigos = Amigo.all
    render json: @amigos
  end

  # GET /amigos/1
  def show
    render json: @amigo
  end

  # POST /amigos
  def create
    @amigo = Amigo.new(amigo_params)
    if @amigo.save
      @amigo.avatar.attach(params[:avatar]) if params[:avatar].present?
      render json: { 
        amigo: @amigo, 
        avatar_url: url_for(@amigo.avatar) if @amigo.avatar.attached? 
      }, status: :created
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
        :secondary_email,
        :phone_1,
        :phone_2,
        :avatar)
    end
end