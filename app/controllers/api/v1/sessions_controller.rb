module Api
  module V1
    class SessionsController < Devise::SessionsController
      include ActionController::MimeResponds
      include ActionController::Cookies
      respond_to :json

      # # Handle specific JWT-related errors
      # rescue_from JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature do |exception|
      #   Rails.logger.error "JWT Error: #{exception.message}"
      #   render json: { error: 'Invalid or expired token' }, status: :unauthorized
      # end

      # # Handle record not found errors
      # rescue_from ActiveRecord::RecordNotFound do |exception|
      #   Rails.logger.error "Record Not Found: #{exception.message}"
      #   render json: { error: 'Resource not found' }, status: :not_found
      # end

      # # Catch all other errors
      # rescue_from StandardError do |exception|
      #   Rails.logger.error "SessionsController - Error: #{exception.message}"
      #   Rails.logger.error exception.backtrace.join("\n") # Log the full backtrace for debugging
      #   render json: { error: 'Internal Server Error', message: exception.message }, status: :internal_server_error
      # end

      before_action :authenticate_amigo!, only: [:show]
      before_action :set_default_format

      JWT_EXPIRATION_TIME = 24.hours.from_now.to_i

      def create
        # Authenticate the amigo (user)
        amigo = authenticate_amigo(params[:amigo])
        
        if amigo.nil?
          Rails.logger.warn "SessionsController - Failed login attempt for login attribute: #{params.dig(:amigo, :login_attribute)}"
          render json: { error: 'Invalid credentials' }, status: :unauthorized
          return
        end

        Rails.logger.info "SessionsController - Authentication successful for Amigo ID: #{amigo.id}"

        # Generate and set the JWT token
        token = generate_jwt(amigo)
        set_jwt_cookie(token)
      
        Rails.logger.info "SessionsController - Successfully generated and set JWT cookie."

        # Generate CSRF token for subsequent requests after login
        csrf_token = form_authenticity_token
        response.set_header('X-CSRF-Token', csrf_token)

        render json: {
          status: { code: 200, message: 'Logged in successfully.' },
          data: { amigo: amigo, csrf_token: csrf_token, jwt: token }
        }, status: :ok
      
        Rails.logger.info "Response Headers after render: #{response.headers.to_h}"
      end

      def verify_token
        token = cookies.signed[:jwt]
        Rails.logger.info "VerifyToken: Received request. JWT Token: #{token.inspect}"
        
        if token.present?
          begin
            decoded_token = JsonWebToken.decode(token)
            Rails.logger.info "VerifyToken: Token decoded successfully. Payload: #{decoded_token}"

            # Check if token is expired
            if decoded_token['exp'] < Time.now.to_i
              Rails.logger.warn "VerifyToken: Token has expired."
              render json: { valid: false }, status: :unauthorized
              return
            end

            render json: { valid: true }, status: :ok
          rescue JWT::DecodeError, JWT::ExpiredSignature => e
            Rails.logger.error "VerifyToken: Token decode failed: #{e.message}"
            render json: { valid: false }, status: :unauthorized
          end
        else
          Rails.logger.warn "VerifyToken: No JWT token present"
          render json: { valid: false }, status: :unauthorized
        end
      end

      def destroy
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

      protected

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

            render json: { token: new_token, csrf_token: csrf_token }, status: :ok
          rescue JWT::DecodeError
            render json: { error: 'Invalid token' }, status: :unauthorized
          end
        else
          render json: { error: 'Token missing' }, status: :unauthorized
        end
      end

      private

      def set_default_format
        request.format = :json
      end

      def set_jwt_cookie(token)
        cookies.signed[:jwt] = {
          value: token,
          httponly: true,
          same_site: :none,            # Required for cross-origin cookies
          secure: request.ssl?,        # Uses SSL for secure connections
          expires: Time.at(JWT_EXPIRATION_TIME) # Set the cookie expiration
        }
        Rails.logger.info "SessionsController - JWT cookie set."
      end

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
          sub: amigo.id,
          exp: JWT_EXPIRATION_TIME,
          jti: SecureRandom.uuid,
          scp: 'amigo'
        }
        Rails.logger.debug "SessionsController - JWT payload before encoding: #{payload.inspect}"

        token = JsonWebToken.encode(payload)
        Rails.logger.info "SessionsController - Generated token."
        token
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