module Api
  module V1
    class AmigosController < ApplicationController
      before_action :authenticate_amigo!, only: [:index, :show, :update, :destroy]
      before_action :set_amigo, only: [:show, :update, :destroy]
      before_action :authorize_amigo!, only: [:destroy]
      helper_method :current_amigo

      def index
        Rails.logger.info("amigos_controller.rb - Is Amigo signed in? #{amigo_signed_in?}")
        @amigos = Amigo.all
        Rails.logger.debug "Amigos: #{@amigos.to_json}"
        
        # ActiveModel Serializers will automatically handle serialization based on AmigoSerializer
        render json: @amigos, status: :ok
      end    

      def show
        if @amigo.avatar.attached?
          avatar_url = rails_blob_path(@amigo.avatar, disposition: "attachment", only_path: true)
        else
          avatar_url = ActionController::Base.helpers.asset_path('default-amigo-avatar.png') # Path to your default avatar in the assets folder
        end
      
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

      def create
        @amigo = Amigo.new(amigo_params.except(:avatar))
      
        if params[:amigo][:avatar]
          @amigo.attach_avatar_by_identifier(params[:amigo][:avatar])
        else
          attach_default_avatar(@amigo)
        end
      
        if @amigo.save
          avatar_url = rails_blob_path(@amigo.avatar, disposition: "attachment", only_path: true)
          if @amigo.avatar.attached?
            render json: @amigo.as_json.merge(avatar_url: avatar_url), status: :created
          else
            render json: @amigo.errors, status: :unprocessable_entity
          end
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

      def amigo_params
        params.require(:amigo).permit(:first_name, :last_name, :user_name, :email, :secondary_email, :unformatted_phone_1, :unformatted_phone_2, :password, :avatar)
      end
      
      def attach_default_avatar(amigo)
        default_avatar = ActiveStorage::Blob.find_by(filename: 'default-amigo-avatar.svg') # Adjust this to your actual file name and storage logic
        if default_avatar
          amigo.avatar.attach(default_avatar)
        end
      end

      def authenticate_amigo!
        token = request.headers['Authorization']&.split(' ')&.last || cookies.signed[:jwt]
        Rails.logger.info "Authenticate Amigo - Token: #{token}"
      
        if token.present?
          begin
            decoded_token = JsonWebToken.decode(token)
            Rails.logger.info "Authenticate Amigo - Decoded Token: #{decoded_token}"
            @current_amigo = Amigo.find(decoded_token[:sub])
          rescue JWT::DecodeError => e
            Rails.logger.error "Authenticate Amigo - JWT Decode Error: #{e.message}"
            return render json: { error: 'Invalid token' }, status: :unauthorized
          rescue ActiveRecord::RecordNotFound => e
            Rails.logger.error "Authenticate Amigo - Amigo Not Found: #{e.message}"
            return render json: { error: 'Amigo not found' }, status: :not_found
          end
        else
          Rails.logger.warn "Authenticate Amigo - No Token Provided"
          return render json: { error: 'Token missing' }, status: :unauthorized
        end
      
        # If authentication fails for any reason, handle unauthorized access
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_amigo
      end     
    end
  end
end