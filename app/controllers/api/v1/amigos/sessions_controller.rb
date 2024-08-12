module Api
  module V1
    module Amigos
      class SessionsController < Devise::SessionsController
        include ActionController::MimeResponds
        include ActionController::Cookies
        respond_to :json

        before_action :authenticate_amigo!, only: [:show]

        def create
          unless params[:amigo]
            Rails.logger.error "SessionsController - Missing amigo params"
            return render json: { status: 400, message: 'Bad Request: Missing amigo parameters' }, status: :bad_request
          end

          amigo = Amigo.find_for_database_authentication(login_attribute: params[:amigo][:login_attribute])

          if amigo&.valid_password?(params[:amigo][:password])
            payload = {
              sub: amigo.id,
              exp: 24.hours.from_now.to_i,
              jti: SecureRandom.uuid,
              scp: 'amigo'
            }
            Rails.logger.debug "SessionsController - JWT payload before encoding: #{payload.inspect}"
            token = JsonWebToken.encode(payload)
            Rails.logger.info "SessionsController - Generated token: #{token}"
            cookies.signed[:jwt] = { value: token, httponly: true, expires: 24.hours.from_now }

            # Safely handle the serialization
            amigo_data = AmigoSerializer.new(amigo).serializable_hash[:data]
            if amigo_data
              amigo_attributes = amigo_data[:attributes]
            else
              Rails.logger.error "SessionsController - Serialization error: No data returned for amigo."
              amigo_attributes = {}
            end

            render json: {
              status: {
                code: 200,
                message: 'Logged into Amigos Unite successfully.',
                data: {
                  amigo: amigo_attributes,
                  jwt: token
                }
              }
            }, status: :ok
          else
            Rails.logger.warn "SessionsController - Login failed for #{params[:amigo][:login_attribute]}"
            render json: {
              status: {
                code: 401,
                message: 'Login failed'
              }
            }, status: :unauthorized
          end
        rescue => e
          Rails.logger.error "SessionsController - Error during login: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { status: 500, message: 'Internal Server Error' }, status: :internal_server_error
        end

        def destroy
          token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last
          Rails.logger.info "SessionsController - Token received for logout: #{token}"

          if token.present?
            begin
              decoded_token = JWT.decode(token, Rails.application.credentials.dig(:devise_jwt_secret_key)).first
              Rails.logger.info "SessionsController - Decoded token for logout: #{decoded_token}"

              JwtDenylist.revoke_jwt(decoded_token, nil)
              cookies.delete(:jwt)
              render json: { status: 200, message: 'Logged out of Amigos Unite successfully.' }, status: :ok
            rescue JWT::DecodeError => e
              Rails.logger.error "SessionsController - JWT Decode Error: #{e.message}"
              render json: { status: 401, message: 'Invalid token' }, status: :unauthorized
            rescue => e
              Rails.logger.error "SessionsController - Error during token revocation: #{e.message}"
              render json: { status: 500, message: 'Internal Server Error during logout' }, status: :internal_server_error
            end
          else
            render json: { status: 401, message: 'Authorization header or cookie is missing' }, status: :unauthorized
          end
        end

        private

        def respond_with(resource, _opts = {})
          render json: {
            status: { code: 200, message: 'Logged in successfully.' },
            data: resource
          }, status: :ok
        end

        def respond_to_on_destroy
          token = request.headers['Authorization']&.split(' ')&.last || cookies.signed[:jwt]
          Rails.logger.info "SessionsController - Token received for respond_to_on_destroy: #{token}"

          if token.present?
            begin
              jwt_payload = JWT.decode(token, Rails.application.credentials.dig(:devise_jwt_secret_key)).first
              current_amigo = Amigo.find(jwt_payload['sub'])

              if current_amigo
                render json: {
                  status: 200,
                  message: 'Logged out successfully.'
                }, status: :ok
              else
                render json: {
                  status: 401,
                  message: 'User has no active session.'
                }, status: :unauthorized
              end
            rescue JWT::DecodeError => e
              render json: {
                status: 401,
                message: e.message
              }, status: :unauthorized
            end
          else
            render json: {
              status: 401,
              message: 'Authorization header or cookie is missing'
            }, status: :unauthorized
          end
        end
      end
    end
  end
end