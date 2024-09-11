module Api
  module V1
    class SessionsController < Devise::SessionsController
      include ActionController::MimeResponds
      include ActionController::Cookies
      respond_to :json

      before_action :authenticate_amigo!, only: [:show]

      JWT_EXPIRATION_TIME = 24.hours.from_now.to_i

      def create
        # Authenticate the amigo (user)
        amigo = authenticate_amigo(params[:amigo])
        
        unless amigo
          Rails.logger.error "SessionsController - Authentication failed."
          render json: { error: 'Invalid credentials' }, status: :unauthorized
          return
        end
      
        Rails.logger.info "SessionsController - Authentication successful for Amigo ID: #{amigo.id}"
      
        # Generate and set the JWT token
        token = generate_jwt(amigo)
        set_jwt_cookie(token)
      
        Rails.logger.info "SessionsController - Successfully generated and set JWT cookie."
      
        # Generate CSRF token (for subsequent requests after login)
        csrf_token = form_authenticity_token  # Generate CSRF token

        response.set_header('X-CSRF-Token', form_authenticity_token)
        
        # Respond with both the JWT (in a cookie) and CSRF token in the response body
        render json: {
          status: { code: 200, message: 'Logged in successfully.' },
          data: { amigo: amigo, csrf_token: csrf_token }  # Send CSRF token to the client
        }, status: :ok
      end      
      
      # Action to serve CSRF token
      def create_csrf
        csrf_token = form_authenticity_token
        render json: { csrf_token: csrf_token }, status: :ok
      end
      
      def destroy
        # Verify CSRF token before processing the logout request
        csrf_token = request.headers['X-CSRF-Token']
        unless valid_authenticity_token?(session, csrf_token)
          render json: { error: 'Invalid CSRF token' }, status: :unauthorized and return
        end
      
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
      
      # Generate JWT for the amigo (user)
      def generate_jwt(amigo)
        payload = {
          sub: amigo.id,                  # Subject of the token (usually the amigo's ID)
          exp: JWT_EXPIRATION_TIME,       # Expiration time
          jti: SecureRandom.uuid,         # Unique identifier for the token (used for revocation)
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
          value: token,                      # Store the JWT token in the cookie
          httponly: true,                    # Ensure the cookie is only accessible by the backend
          same_site: :lax,                   # Control the cross-site request behavior of the cookie
          secure: Rails.env.production?,     # Only send the cookie over HTTPS in production
          expires: Time.at(JWT_EXPIRATION_TIME)  # Cookie expiration time matches the JWT expiration
        }
        Rails.logger.info "SessionsController - JWT cookie set with value: #{cookies.signed[:jwt]}"
      end

      def verify_token
        token = cookies.signed[:jwt]
        if token.present?
          begin
            decoded_token = JsonWebToken.decode(token)
            render json: { valid: true }, status: :ok
          rescue JWT::DecodeError, JWT::ExpiredSignature
            render json: { valid: false }, status: :unauthorized
          end
        else
          render json: { valid: false }, status: :unauthorized
        end
      end

      def refresh
        token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last
        if token.present?
          begin
            payload = JsonWebToken.decode(token)
            amigo = Amigo.find(payload['sub'])
      
            # Generate a new JWT
            new_token = generate_jwt(amigo)
            set_jwt_cookie(new_token)
      
            # Generate a new CSRF token
            csrf_token = form_authenticity_token
      
            # Send the new JWT (in the cookie) and CSRF token (in the response)
            render json: { token: new_token, csrf_token: csrf_token }, status: :ok
          rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
          end
        else
          render json: { error: 'Token missing' }, status: :unauthorized
        end
      end           
      
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