module Api
  module V1
    module Amigos
      class SessionsController < Devise::SessionsController
        include ActionController::MimeResponds
        include ActionController::Cookies
        respond_to :json

        before_action :authenticate_amigo!, only: [:show]

        def create
          Rails.logger.info "SessionsController - Starting login process"
        
          amigo = authenticate_amigo(params[:amigo])
          unless amigo
            Rails.logger.error "SessionsController - Authentication failed."
            return
          end
        
          Rails.logger.info "SessionsController - Authentication successful for Amigo ID: #{amigo.id}"
        
          token = generate_jwt(amigo)
          set_jwt_cookie(token)
        
          Rails.logger.info "SessionsController - Successfully generated and set JWT cookie."
        
          render json: {
            status: {
              code: 200,
              message: 'Logged into Amigos Unite successfully.',
              data: {
                amigo: amigo,   # Pass the ActiveRecord object directly
                jwt: token
              }
            }
          }, status: :ok  # No need to manually handle serialization here
        rescue => e
          handle_login_error(e)
        end  
        
        def destroy
          super
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
        
        def authenticate_amigo(amigo_params)
          unless amigo_params
            log_and_render_error("SessionsController - Missing amigo params", :bad_request, 'Bad Request: Missing amigo parameters')
            return nil
          end
        
          Rails.logger.info "SessionsController - Finding Amigo for login attribute: #{amigo_params[:login_attribute]}"
        
          amigo = Amigo.find_for_database_authentication(login_attribute: amigo_params[:login_attribute])
        
          if amigo&.valid_password?(amigo_params[:password])
            Rails.logger.info "SessionsController - Amigo found and password valid."
            amigo
          else
            log_and_render_error("SessionsController - Invalid login credentials for #{amigo_params[:login_attribute]}", :unauthorized, 'Login failed')
            nil
          end
        end
        
        def generate_jwt(amigo)
          payload = {
            sub: amigo.id,                 # Subject of the token, usually the amigo's ID
            exp: 24.hours.from_now.to_i,    # Expiration time
            jti: SecureRandom.uuid,         # Unique identifier for the token
            scp: 'amigo'                    # Scope of the token
          }
          Rails.logger.debug "SessionsController - JWT payload before encoding: #{payload.inspect}"
        
          token = JsonWebToken.encode(payload) # Encodes the payload into a JWT
          Rails.logger.info "SessionsController - Generated token: #{token}"
        
          token # Return the generated JWT token
        end
        
        # Set the JWT token in a secure signed cookie
        def set_jwt_cookie(token)
          cookies.signed[:jwt] = {
            value: token,
            httponly: true,                # Ensures the cookie is only accessible by the backend
            same_site: :lax,               # Controls the cross-site request behavior of the cookie
            secure: Rails.env.production?, # Only send over HTTPS in production
            expires: 24.hours.from_now     # Cookie expiration time
          }
          Rails.logger.info "SessionsController - JWT cookie set with value: #{cookies.signed[:jwt]}"
        end

        def verify_token
          if current_amigo
            render json: { valid: true }, status: :ok
          else
            render json: { valid: false }, status: :unauthorized
          end
        end

        def refresh
          token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last

          begin
            payload = JsonWebToken.decode(token)
            amigo = Amigo.find(payload['sub'])

            # Generate a new token
            new_token = generate_jwt(amigo)
            set_jwt_cookie(new_token)

            render json: { token: new_token }, status: :ok
          rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'Amigo not found' }, status: :unauthorized
          end
        end      
        # def refresh
        #   refresh_token = request.headers['Authorization']&.split(' ')&.last
        #   payload = JsonWebToken.decode(refresh_token)
        #   if payload && Amigo.exists?(id: payload[:sub])
        #     new_token = JsonWebToken.encode(sub: payload[:sub])
        #     render json: { token: new_token }
        #   else
        #     render json: { error: 'Invalid refresh token' }, status: :unauthorized
        #   end
        # end
        
        def log_and_render_error(log_message, status_code, response_message)
          Rails.logger.error log_message
          render json: {
            status: {
              code: status_code,
              message: response_message
            }
          }, status: status_code
        end
        
        def handle_login_error(exception)
          Rails.logger.error "SessionsController - Error during login: #{exception.message}"
          Rails.logger.error exception.backtrace.join("\n")
          render json: { status: 500, message: 'Internal Server Error' }, status: :internal_server_error
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
                  message: 'Amigo has no active session.'
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