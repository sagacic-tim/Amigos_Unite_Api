module Api
  module V1
    class SessionsController < Devise::SessionsController
      include ActionController::MimeResponds
      include ActionController::Cookies
      respond_to :json

      # Handle specific JWT-related errors
      rescue_from JWT::DecodeError, JWT::VerificationError, JWT::ExpiredSignature do |exception|
        Rails.logger.error "JWT Error: #{exception.message}"
        render json: { error: 'Invalid or expired token' }, status: :unauthorized
      end

      # Handle record not found errors
      rescue_from ActiveRecord::RecordNotFound do |exception|
        Rails.logger.error "Record Not Found: #{exception.message}"
        render json: { error: 'Resource not found' }, status: :not_found
      end

      # Catch all other errors
      rescue_from StandardError do |exception|
        Rails.logger.error "SessionsController - Error: #{exception.message}"
        Rails.logger.error exception.backtrace.join("\n")
        render json: { error: 'Internal Server Error' }, status: :internal_server_error
      end

      before_action :authenticate_amigo!, only: [:show]
      before_action :set_default_format
      before_action :verify_csrf_token, only: [:create, :refresh] # Add this line

      JWT_EXPIRATION_TIME = 24.hours.from_now.to_i

      def create
        amigo = authenticate_amigo(params[:amigo])

        if amigo.nil?
          Rails.logger.warn "Failed login attempt for login attribute: #{params.dig(:amigo, :login_attribute)}"
          return render json: { error: 'Invalid credentials' }, status: :unauthorized
        end

        Rails.logger.info "Authentication successful for Amigo ID: #{amigo.id}"
        token = generate_jwt(amigo)
        set_jwt_cookie(token)

        csrf_token = form_authenticity_token
        response.set_header('X-CSRF-Token', csrf_token)

        render json: {
          status: { code: 200, message: 'Logged into Amigos Unite successfully.' },
          data: { amigo: amigo, csrf_token: csrf_token, jwt: token }
        }, status: :ok
      end

      def verify_token
        token = cookies.signed[:jwt]
        Rails.logger.info "VerifyToken: Received request. JWT Token: #{token.inspect}"

        unless token.present?
          Rails.logger.warn "VerifyToken: No JWT token present"
          return render json: { valid: false }, status: :unauthorized
        end

        begin
          decoded_token = JsonWebToken.decode(token)
          Rails.logger.info "VerifyToken: Token decoded successfully. Payload: #{decoded_token}"

          if decoded_token['exp'] < Time.now.to_i
            Rails.logger.warn "VerifyToken: Token has expired."
            return render json: { valid: false }, status: :unauthorized
          end

          render json: { valid: true }, status: :ok
        rescue JWT::DecodeError, JWT::ExpiredSignature => e
          Rails.logger.error "VerifyToken: Token decode failed: #{e.message}"
          render json: { valid: false }, status: :unauthorized
        end
      end

      def destroy
        token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last
        Rails.logger.info "Token received for logout: #{token}"

        if token.present?
          begin
            decoded_token = JWT.decode(token, Rails.application.credentials.dig(:devise_jwt_secret_key)).first
            JwtDenylist.revoke_jwt(decoded_token, nil)
            cookies.delete(:jwt)
            render json: { status: 200, message: 'Logged out of Amigos Unite successfully.' }, status: :ok
          rescue JWT::DecodeError => e
            Rails.logger.error "JWT Decode Error during logout: #{e.message}"
            render json: { error: 'Invalid token' }, status: :unauthorized
          rescue => e
            Rails.logger.error "Error during token revocation: #{e.message}"
            render json: { error: 'Internal Server Error during logout' }, status: :internal_server_error
          end
        else
          render json: { error: 'Authorization header or cookie is missing' }, status: :unauthorized
        end
      end

      def refresh
        token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last

        unless token.present?
          return render json: { error: 'Token missing' }, status: :unauthorized
        end

        begin
          payload = JsonWebToken.decode(token)
          amigo = Amigo.find(payload['sub'])

          new_token = generate_jwt(amigo)
          set_jwt_cookie(new_token)
          csrf_token = form_authenticity_token

          render json: { success: true, token: new_token }, status: :ok
        rescue => e
          render json: { error: e.message }, status: :unprocessable_entity
        end
      end

      protected

      def verify_csrf_token
        csrf_token_from_request = request.headers['X-CSRF-Token']
        csrf_token_from_server = form_authenticity_token
      
        Rails.logger.info "Received CSRF token: #{csrf_token_from_request}"
        Rails.logger.info "Expected CSRF token: #{csrf_token_from_server}"
      
        unless csrf_token_from_request.present? && csrf_token_from_request == csrf_token_from_server
          Rails.logger.error "CSRF token mismatch: Received: #{csrf_token_from_request}, Expected: #{csrf_token_from_server}"
          render json: { error: 'Invalid CSRF token' }, status: :unauthorized
        end
      end

      private

      def set_default_format
        request.format = :json
      end

      def set_jwt_cookie(token)
        cookies.signed[:jwt] = {
          value: token,
          same_site: :none,
          secure: true, # Always require HTTPS
          expires: Time.at(JWT_EXPIRATION_TIME)
        }
        Rails.logger.info "JWT cookie set with expiration: #{JWT_EXPIRATION_TIME}"
      end

      def authenticate_amigo(amigo_params)
        unless amigo_params
          log_and_render_error("Missing amigo params", :bad_request, 'Bad Request: Missing amigo parameters')
          return nil
        end

        Rails.logger.info "Finding Amigo for login attribute: #{amigo_params[:login_attribute]}"
        amigo = Amigo.find_for_database_authentication(login_attribute: amigo_params[:login_attribute])

        if amigo&.valid_password?(amigo_params[:password])
          Rails.logger.info "Amigo authenticated successfully."
          amigo
        else
          log_and_render_error("Invalid login credentials for #{amigo_params[:login_attribute]}", :unauthorized, 'Login failed')
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
        Rails.logger.debug "JWT payload before encoding: #{payload.inspect}"

        JsonWebToken.encode(payload)
      end

      def log_and_render_error(log_message, status_code, error_message)
        Rails.logger.error log_message
        render json: { error: error_message }, status: status_code
      end
    end
  end
end