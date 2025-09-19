module Api
  module V1
    class AmigosController < ApplicationController
      before_action :authenticate_amigo!
      before_action :verify_csrf_token, only: [:create, :update, :destroy]
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
    end
  end
end
