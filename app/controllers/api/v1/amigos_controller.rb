# app/controllers/api/v1/amigos_controller.rb
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
        amigos = Amigo.all

        # emit avatar_url for every amigo in the list
        payload = amigos.map { |a| amigo_json(a) }
        render json: payload, status: :ok
      end

      def show
        render json: amigo_json(@amigo), status: :ok
      end

      def create
        @amigo = Amigo.new(amigo_params.except(:avatar))

        if params[:amigo][:avatar]
          @amigo.attach_avatar_by_identifier(params[:amigo][:avatar])
        else
          attach_default_avatar(@amigo)
        end

        if @amigo.save
          render json: amigo_json(@amigo), status: :created
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      def update
        if @amigo.update(amigo_params)
          render json: amigo_json(@amigo), status: :ok
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
        params.require(:amigo).permit(
          :first_name, :last_name, :user_name, :email, :secondary_email,
          :unformatted_phone_1, :unformatted_phone_2, :password, :avatar
        )
      end

      # Unified JSON shape with avatar_url
      def amigo_json(amigo)
        amigo.as_json.merge(avatar_url: computed_avatar_path_for(amigo))
      end

      # Returns a *path* (leading slash) that the frontend should prefix with the API origin.
      def computed_avatar_path_for(amigo)
        if amigo.avatar.attached?
          # Use "inline" so browsers render, not download; keep only_path so FE can prefix its own origin
          rails_blob_path(amigo.avatar, disposition: "inline", only_path: true)
        else
          # This reference should resolve to /assets/... at runtime
          ActionController::Base.helpers.asset_path('default-amigo-avatar.png')
        end
      end

      def attach_default_avatar(amigo)
        default_avatar = ActiveStorage::Blob.find_by(filename: 'default-amigo-avatar.svg')
        amigo.avatar.attach(default_avatar) if default_avatar
      end
    end
  end
end
