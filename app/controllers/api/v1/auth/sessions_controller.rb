# app/controllers/api/v1/auth/sessions_controller.rb
module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController 
        prepend_before_action -> { request.env['devise.mapping'] = Devise.mappings[:amigo]}
        before_action :ensure_devise_mapping, only: %i[create refresh verify_token]
        include ActionController::MimeResponds
        include ActionController::Cookies
        include ActionController::RequestForgeryProtection

        protect_from_forgery with: :exception
        respond_to :json

        before_action :set_default_format
        before_action :authenticate_amigo!, only: [:show]

        rescue_from JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature do |e|
          Rails.logger.error "JWT Error: #{e.message}"
          render_error('Invalid or expired token', :unauthorized)
        end

        rescue_from ActiveRecord::RecordNotFound do |e|
          Rails.logger.error "Record Not Found: #{e.message}"
          render_error('Resource not found', :not_found)
        end

        rescue_from StandardError do |e|
          Rails.logger.error "Unhandled error in SessionsController: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render_error('Internal Server Error', :internal_server_error)
        end

        JWT_EXPIRATION_TIME = 24.hours.from_now.to_i

        # POST /api/v1/login
        def create
          request.env['devise.mapping'] ||= Devise.mappings[:amigo]
          Rails.logger.info "[MAPPING] #{request.env['devise.mapping'].inspect}"

          amigo = authenticate_amigo(params[:amigo])
          return unless amigo

          token = generate_jwt(amigo)
          set_jwt_cookie(token)

          # Emit a CSRF-TOKEN cookie for the front end to pick up
          cookies['CSRF-TOKEN'] = {
            value:     form_authenticity_token,
            same_site: Rails.env.development? ? :none : :strict,
            secure:    Rails.env.production?,
            http_only: false
          }

          serialized = AmigoSerializer.new(amigo).serializable_hash
          Rails.logger.info "[SERIALIZER OUTPUT] #{serialized.inspect}"

          amigo_attrs = extract_amigo_attributes(serialized)

          unless amigo_attrs
            Rails.logger.error "Unexpected serializer shape during login: #{serialized.inspect}"
            render_error('Serialization error', :internal_server_error) and return
          end

          render json: {
            status: { code: 200, message: 'Logged in successfully.' },
            data: {
              amigo:          amigo_attrs,
              jwt_expires_at: Time.at(JWT_EXPIRATION_TIME).utc.iso8601
            }
          }, status: :ok
        end

        # DELETE /api/v1/logout
        def destroy
          token = cookies.signed[:jwt] || bearer_token
          Rails.logger.info "Logout requested with token: #{token&.truncate(30)}..."

          if token.present?
            begin
              payload = JWT.decode(token, Rails.application.credentials.dig(:devise_jwt_secret_key)).first
              JwtDenylist.revoke_jwt(payload, nil)
              cookies.delete(:jwt)
              cookies.delete('CSRF-TOKEN')

              render json: { status: { code: 200, message: 'Logged out successfully.' } }, status: :ok
            rescue JWT::DecodeError => e
              Rails.logger.error "JWT Decode Error: #{e.message}"
              render_error('Invalid token during logout', :unauthorized)
            end
          else
            render_error('Authorization header or cookie missing', :unauthorized)
          end
        end

        # GET /api/v1/refresh_token
        def refresh
          token = cookies.signed[:jwt] || bearer_token
          return render_error('Token missing', :unauthorized) unless token

          begin
            payload = JsonWebToken.decode(token)
            amigo   = Amigo.find(payload['sub'])

            new_token = generate_jwt(amigo)
            set_jwt_cookie(new_token)

            # Renew the CSRF-TOKEN cookie as well
            cookies['CSRF-TOKEN'] = {
              value:     form_authenticity_token,
              secure:    Rails.env.production?,
              same_site: Rails.env.development? ? :none : :strict
            }

            render json: {
              status: { code: 200, message: 'Token refreshed successfully.' },
              data:   { jwt_expires_at: Time.at(JWT_EXPIRATION_TIME).utc.iso8601 }
            }, status: :ok
          rescue => e
            Rails.logger.error "Refresh token error: #{e.message}"
            render_error(e.message, :unprocessable_entity)
          end
        end

        # GET /api/v1/verify_token
        def verify_token
          token = cookies.signed[:jwt] || bearer_token

          if token.blank?
            return render json: { valid: false, reason: 'Missing token' }, status: :unauthorized
          end

          begin
            payload = JsonWebToken.decode(token)
            exp_time = Time.at(payload['exp']).utc
            if exp_time < Time.now.utc
              render json: { valid: false, reason: 'Token expired' }, status: :unauthorized
            else
              render json: { valid: true, expires_at: exp_time.iso8601 }, status: :ok
            end
          rescue => e
            render json: { valid: false, reason: e.message }, status: :unauthorized
          end
        end

        private

        def ensure_devise_mapping
          request.env['devise.mapping'] ||= Devise.mappings[:amigo]
        end

        def bearer_token
          request.headers['Authorization']&.split(' ')&.last
        end

        def set_default_format
          request.format = :json
        end

        def set_jwt_cookie(token)
          cookies.signed[:jwt] = {
            value:      token,
            httponly:   true,
            secure:     Rails.env.production?,
            same_site:  Rails.env.development? ? :none : :strict,
            expires:    Time.at(JWT_EXPIRATION_TIME)
          }
          Rails.logger.info "JWT cookie set to expire at #{Time.at(JWT_EXPIRATION_TIME).utc.iso8601}"
        end

        def authenticate_amigo(amigo_params)
          unless amigo_params
            render_error('Missing login parameters', :bad_request)
            return nil
          end

          amigo = Amigo.find_for_database_authentication(login_attribute: amigo_params[:login_attribute])
          if amigo&.valid_password?(amigo_params[:password])
            return amigo
          else
            render_error('Invalid login credentials', :unauthorized)
            return nil
          end
        end

        def generate_jwt(amigo)
          payload = {
            sub: amigo.id,
            exp: JWT_EXPIRATION_TIME,
            jti: SecureRandom.uuid,
            scp: 'amigo'
          }
          JsonWebToken.encode(payload)
        end

        def extract_amigo_attributes(serialized)
          if serialized.dig(:data, :attributes)
            serialized[:data][:attributes]
          elsif serialized[:attributes]
            serialized[:attributes]
          else
            Rails.logger.warn "Serializer returned unexpected shape: #{serialized.inspect}"
            serialized # fallback to whatever came back
          end
        end

        def render_error(message, status_code)
          render json: {
            status: { code: Rack::Utils::SYMBOL_TO_STATUS_CODE[status_code], message: message },
            errors: [message]
          }, status: status_code
        end
      end
    end
  end
end
