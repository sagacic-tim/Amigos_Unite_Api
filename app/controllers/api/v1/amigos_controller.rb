# app/controllers/api/v1/amigos_controller.rb
module Api
  module V1
    class AmigosController < ApplicationController
      include ActionController::Cookies
      include ActionController::MimeResponds

      # NOTE: we no longer use Devise's authenticate_amigo! for :me, because
      # our auth is driven by the JWT cookie / Authorization header we manage
      # ourselves (see SessionsController).
      # before_action :authenticate_amigo!, only: [:me]

      before_action :verify_csrf_token, only: [:create, :update, :destroy]

      before_action :set_amigo,        only: [:show, :update, :destroy]
      before_action :authorize_amigo!, only: [:destroy]

      helper_method :current_amigo

      # GET /api/v1/amigos
      def index
        amigos = Amigo.includes(avatar_attachment: :blob).all
        render json: amigos,
               each_serializer: AmigoIndexSerializer,
               adapter: :attributes,       # ⬅️ important
               status: :ok
      end

      # GET /api/v1/amigos/:id
      def show
        render json: @amigo,
               serializer: AmigoSerializer,
               adapter: :attributes,       # ⬅️ same here
               status: :ok
      end

      # POST /api/v1/amigos
      def create
        @amigo = Amigo.new(amigo_params.except(:avatar))

        if (upload = params.dig(:amigo, :avatar)).present?
          if upload.is_a?(ActionDispatch::Http::UploadedFile)
            @amigo.avatar.attach(upload)
            @amigo.avatar_source = 'upload'
          else
            @amigo.attach_avatar_by_identifier(upload)
          end
        else
          attach_default_avatar(@amigo)
        end

        if @amigo.save
          render json: amigo_json(@amigo), status: :created
        else
          render json: @amigo.errors, status: :unprocessable_content
        end
      end

      # PATCH/PUT /api/v1/amigos/:id
      def update
        if params.dig(:amigo, :avatar).present?
          @amigo.avatar_source = 'upload'
        else
          @amigo.avatar_source     = params.dig(:amigo, :avatar_source).presence || @amigo.avatar_source
          @amigo.avatar_remote_url = params.dig(:amigo, :avatar_remote_url).presence if @amigo.avatar_source == 'url'
        end

        if @amigo.update(amigo_params)
          unless @amigo.avatar_source.blank? || @amigo.avatar_source == 'upload'
            ok = @amigo.apply_avatar_preference!
            return render json: { errors: @amigo.errors.full_messages }, status: :unprocessable_content unless ok
          end

          render json: amigo_json(@amigo), status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/amigos/:id
      def destroy
        if @amigo.destroy
          render json: { message: 'Amigo deleted successfully' }, status: :ok
        else
          render json: @amigo.errors, status: :unprocessable_content
        end
      end

      # GET /api/v1/me
      #
      # This now mirrors your SessionsController behavior: it reads the
      # JWT from the signed cookie (or Authorization header), decodes it,
      # and returns the current amigo payload, or 401 if anything is wrong.
      def me
        token = cookies.signed[:jwt] || bearer_token

        if token.blank?
          return render json: {
            status: { code: 401, message: 'Missing token' },
            errors: ['Missing token']
          }, status: :unauthorized
        end

        begin
          payload  = JsonWebToken.decode(token) # raises on invalid/expired
          amigo_id = (payload[:sub] || payload['sub']).to_i
          amigo    = Amigo.find(amigo_id)

          render json: {
            status: { code: 200, message: 'OK' },
            data:   { amigo: amigo_json(amigo) }
          }, status: :ok

        rescue JWT::ExpiredSignature
          render json: {
            status: { code: 401, message: 'Token expired' },
            errors: ['Token expired']
          }, status: :unauthorized

        rescue JWT::DecodeError => e
          render json: {
            status: { code: 401, message: 'Invalid token' },
            errors: [e.message]
          }, status: :unauthorized

        rescue ActiveRecord::RecordNotFound
          render json: {
            status: { code: 401, message: 'Amigo not found' },
            errors: ['Amigo not found']
          }, status: :unauthorized
        end
      end

      private

      def set_amigo
        @amigo = Amigo.find(params[:id])
      end

      # Single, reusable JSON shape (prevents leaking internal columns)
      def amigo_json(amigo)
        amigo.as_json(only: %i[id user_name email first_name last_name])
             .merge(avatar_url: amigo.avatar_url_with_buster)
      end

      def attach_default_avatar(amigo)
        path = Rails.root.join("public/images/default-amigo-avatar.png")
        amigo.avatar.attach(io: File.open(path), filename: "default-amigo-avatar.png", content_type: "image/png") if File.exist?(path)
      end

      def amigo_params
        params.require(:amigo).permit(
          :first_name, :last_name, :user_name, :email, :secondary_email,
          :phone_1, :phone_2,            # ⬅️ use the real columns
          :password,
          :avatar,
          :avatar_source,
          :avatar_remote_url
        )
      end

      # Mirror SessionsController's helper so we can also accept Authorization: Bearer ...
      def bearer_token
        request.headers['Authorization']&.split(' ')&.last
      end
    end
  end
end
