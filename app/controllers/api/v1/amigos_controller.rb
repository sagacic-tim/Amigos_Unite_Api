# app/controllers/api/v1/amigos_controller.rb
module Api
  module V1
    class AmigosController < ApplicationController
      before_action :authenticate_amigo!, only: [:me]
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

        if (upload = params.dig(:amigo, :avatar)).present?
          # If FE sends a file, attach it; if it sends an identifier string, use your helper.
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
          render json: @amigo.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/amigos/:id
      def update
        # Handle uploaded file first (if any) and mark the source.
        if params.dig(:amigo, :avatar).present?
          @amigo.avatar_source = 'upload'
        else
          # accept preference switches (gravatar|url|default)
          @amigo.avatar_source     = params.dig(:amigo, :avatar_source).presence || @amigo.avatar_source
          @amigo.avatar_remote_url = params.dig(:amigo, :avatar_remote_url).presence if @amigo.avatar_source == 'url'
        end

        if @amigo.update(amigo_params)
          # If user changed source (or uploaded), apply it (fetch gravatar/URL, or default)
          unless @amigo.avatar_source.blank? || @amigo.avatar_source == 'upload'
            ok = @amigo.apply_avatar_preference!
            return render json: { errors: @amigo.errors.full_messages }, status: :unprocessable_entity unless ok
          end

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

      # Single, reusable JSON shape (prevents leaking internal columns)
      def amigo_json(amigo)
        amigo.as_json(only: %i[id user_name email first_name last_name])
             .merge(avatar_url: amigo.avatar_url_with_buster)
      end

      # def computed_avatar_path_for(amigo, size: 80)
      #   if amigo.avatar.attached?
      #     # relative path + cache buster so clients refresh when the job replaces it
      #     path = rails_blob_path(amigo.avatar, disposition: "inline", only_path: true)
      #     ts   = amigo.avatar_synced_at&.to_i
      #     ts ? "#{path}?v=#{ts}" : path
      #   else
      #     # absolute URL; FE must accept absolute or relative (see step 2)
      #     amigo.gravatar_url(size: size) || helpers.asset_path("default-amigo-avatar.png")
      #   end
      # end
      #
      # # Relative path that the frontend can prefix with API origin.
      # # Appends a cache-busting `?v=<timestamp>` so the Details page sees fresh avatars.
      # def avatar_url_with_buster(amigo)
      #   if amigo.avatar.attached?
      #     path  = rails_blob_path(amigo.avatar, disposition: "inline", only_path: true)
      #     stamp = (amigo.avatar_synced_at || amigo.updated_at)&.to_i
      #     stamp ? "#{path}?v=#{stamp}" : path
      #   else
      #     # If you keep your default in /public/images
      #     "/images/default-amigo-avatar.png"
      #   end
      # end


      def attach_default_avatar(amigo)
        path = Rails.root.join("public/images/default-amigo-avatar.png")
        amigo.avatar.attach(io: File.open(path), filename: "default-amigo-avatar.png", content_type: "image/png") if File.exist?(path)
      end


      def amigo_params
        params.require(:amigo).permit(
          :first_name, :last_name, :user_name, :email, :secondary_email,
          :unformatted_phone_1, :unformatted_phone_2,
          :password,
          :avatar,                 # file upload (multipart)
          :avatar_source,          # 'upload' | 'gravatar' | 'url' | 'default'
          :avatar_remote_url       # only when avatar_source='url'
        )
      end
    end
  end
end
