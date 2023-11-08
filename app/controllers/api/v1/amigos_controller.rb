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
      render json: @amigo, status: :created, location: @amigo
    else
      render json: @amigo.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /amigos/1
  def update
    if @amigo.update(amigo_params)
      render json: @amigo
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
      params.require(:amigo).permit(:first_name, :last_name, :user_name, :primary_email, :secondary_email, :phone_1, :phone_2, :date_of_birth, :member_in_good_standing, :available_to_host, :willing_to_donate, :personal_bio)
    end
end
