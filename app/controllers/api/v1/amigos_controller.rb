module Api
  module V1
    class AmigosController < ApplicationController
      before_action :authenticate_amigo!, only: [:show, :update, :destroy]
      before_action :set_amigo, only: [:show, :update, :destroy]
      before_action :authorize_amigo!, only: [:destroy]
      helper_method :current_amigo

      def index
        token = request.headers['Authorization']&.split(' ')&.last
        if token.present?
          payload = JsonWebToken.decode(token)
          Rails.logger.info("amigos_controller.rb - Decoded JWT Payload: #{payload}")
        else
          Rails.logger.info("amigos_controller.rb - No JWT token provided")
        end
        
        Rails.logger.info("amigos_controller.rb - Is Amigo signed in? #{amigo_signed_in?}")
        @amigos = Amigo.all
        render json: @amigos, each_serializer: AmigoSerializer, status: :ok
      end

      def show
        avatar_url = rails_blob_path(@amigo.avatar, disposition: "attachment", only_path: true) if @amigo.avatar.attached?
        render json: @amigo.as_json.merge(avatar_url: avatar_url), status: :ok
      end

      def create
        @amigo = Amigo.new(amigo_params.except(:avatar))

        if params[:amigo][:avatar]
          @amigo.attach_avatar_by_identifier(params[:amigo][:avatar])
        end

        if @amigo.save
          avatar_url = rails_blob_path(@amigo.avatar, disposition: "attachment", only_path: true) if @amigo.avatar.attached?
          render json: @amigo.as_json.merge(avatar_url: avatar_url), status: :created
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      def update
        if @amigo.update(amigo_params)
          avatar_url = rails_blob_path(@amigo.avatar, disposition: "attachment", only_path: true) if @amigo.avatar.attached?
          render json: @amigo.as_json.merge(avatar_url: avatar_url), status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      def destroy
        if @amigo.destroy
          render json: { message: 'Amigo deleted successfully' }, status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      private

      def set_amigo
        @amigo = Amigo.find(params[:id])
      end

      def authorize_amigo!
        render json: { error: 'Not authorized' }, status: :unauthorized unless current_amigo == @amigo
      end

      def amigo_params
        params.require(:amigo).permit(:first_name, :last_name, :user_name, :email, :secondary_email, :phone_1, :phone_2, :password, :avatar)
      end

      def authenticate_amigo!
        token = request.headers['Authorization']&.split(' ')&.last
        Rails.logger.info "Authenticate Amigo - Token: #{token}"
        if token.present?
          begin
            decoded_token = JsonWebToken.decode(token)
            Rails.logger.info "Authenticate Amigo - Decoded Token: #{decoded_token}"
            @current_amigo = Amigo.find(decoded_token[:sub])
          rescue JWT::DecodeError => e
            Rails.logger.error "Authenticate Amigo - JWT Decode Error: #{e.message}"
            @current_amigo = nil
          end
        else
          Rails.logger.warn "Authenticate Amigo - No Token Provided"
          @current_amigo = nil
        end
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_amigo
      end
    end
  end
end