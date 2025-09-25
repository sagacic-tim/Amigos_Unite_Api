# app/controllers/api/v1/amigos_controller.rb
module Api
  module V1
    class AmigosController < ApplicationController
      # Auth only needed for /me; keep the rest as your app policy requires
      before_action :authenticate_amigo!, only: [:me]

      # CSRF for mutating requests (read-only actions are safe without it)
      before_action :verify_csrf_token, only: [:create, :update, :destroy]

      before_action :set_amigo,        only: [:show, :update, :destroy]
      before_action :authorize_amigo!, only: [:destroy]

      helper_method :current_amigo

      # GET /api/v1/amigos
      def index
        Rails.logger.info("amigos_controller.rb - Is Amigo signed in? #{amigo_signed_in?}")
        amigos  = Amigo.all
        payload = amigos.map { |a| amigo_json(a) }
        render json: payload, status: :ok
      end

      # GET /api/v1/amigos/:id
      def show
        render json: amigo_json(@amigo), status: :ok
      end

      # POST /api/v1/amigos
      def create
        @amigo = Amigo.new(amigo_params.except(:avatar))

        if params.dig(:amigo, :avatar).present?
          # If you pass an identifier from FE, keep this helper;
          # otherwise switch to @amigo.avatar.attach(io: ..., filename: ...)
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

      # PATCH/PUT /api/v1/amigos/:id
      def update
        if @amigo.update(amigo_params)
          render json: amigo_json(@amigo), status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/amigos/:id
      def destroy
        if @amigo.destroy
          render json: { message: 'Amigo deleted successfully' }, status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      # GET /api/v1/me
      def me
        amigo = current_amigo
        return render json: { status: { code: 401, message: 'Not authenticated' } }, status: :unauthorized unless amigo

        render json: {
          status: { code: 200, message: 'OK' },
          data:   { amigo: amigo_json(amigo) }
        }, status: :ok
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

      # Single, reusable JSON shape (prevents leaking internal columns)
      def amigo_json(amigo)
        amigo.as_json(only: %i[id user_name email first_name last_name])
             .merge(avatar_url: computed_avatar_path_for(amigo))
      end

      # Relative path that the frontend can prefix with API origin.
      def computed_avatar_path_for(amigo)
        if amigo.avatar.attached?
          # keep only_path so it stays relative; disposition inline for display
          rails_blob_path(amigo.avatar, disposition: "inline", only_path: true)
        else
          # falls back to a relative asset pipeline path
          helpers.asset_path('default-amigo-avatar.png')
        end
      end

      def attach_default_avatar(amigo)
        default_blob = ActiveStorage::Blob.find_by(filename: 'default-amigo-avatar.svg')
        amigo.avatar.attach(default_blob) if default_blob
      end
    end
  end
end
