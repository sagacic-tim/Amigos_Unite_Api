class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  helper_method :current_amigo
  respond_to :json
  before_action :authenticate_request!, only: [:show, :update, :destroy]
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log_request

  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [
      :user_name,
      :email,
      :phone_1,
      :password])
  
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name,
      :last_name,
      :user_name,
      :email,
      :secondary_email,
      :phone_1,
      :phone_2,
      :avatar,
      :password,
      :password_confirmation
    ])    
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :first_name,
      :last_name,
      :user_name,
      :email,
      :secondary_email,
      :phone_1,
      :phone_2,
      :avatar,
      :password,
      :current_password
    ])
  end
  
  def authenticate_current_user!
    authenticate_amigo!  # This is a Devise helper method, tailored for the Amigo model
    Rails.logger.info "Amigo authenticated."
  end

  def current_amigo
    current_amigo ||= warden.authenticate(scope: :amigo)
  end

  private

  def log_request
    Rails.logger.info "Incoming request to #{request.path} with headers: #{request.headers.to_h.except('rack.input', 'action_dispatch.secret_key_base', 'action_dispatch.signed_cookie_salt', 'action_dispatch.encrypted_cookie_salt', 'action_dispatch.encrypted_signed_cookie_salt', 'action_dispatch.authenticated_encrypted_cookie_salt', 'action_dispatch.http_auth_salt', 'action_dispatch.secret_token', 'action_dispatch.cookies_serializer', 'action_dispatch.encrypted_cookie_cipher', 'action_dispatch.signed_cookie_cipher', 'action_dispatch.content_security_policy', 'action_dispatch.content_security_policy_nonce_directives', 'action_dispatch.content_security_policy_report_only')}"
  end

  def authenticate_request!
    Rails.logger.info "Headers: #{request.headers.to_h.select { |k, _| k.match?(/^HTTP_/) }}"
    header = request.headers['Authorization']
    if header.present?
      token = header.split(' ').last
      begin
        @decoded = JsonWebToken.decode(token)
        Rails.logger.debug "Decoded JWT: #{@decoded}"
        
        # Fetch the amigo ID from 'sub' claim of the JWT
        @current_amigo = Amigo.find_by(id: @decoded['sub'])
        
        unless @current_amigo
          Rails.logger.debug "No Amigo found with ID: #{@decoded['sub']}"
          render json: { errors: 'Invalid token or Amigo not found' }, status: :unauthorized
        end
      rescue JWT::DecodeError => e
        Rails.logger.debug "JWT Decode Error: #{e.message}"
        render json: { errors: 'Invalid token' }, status: :unauthorized
      rescue JWT::ExpiredSignature, JWT::VerificationError => e
        Rails.logger.debug "JWT Verification Error or Expired Signature: #{e.message}"
        render json: { errors: 'Token has expired or is invalid' }, status: :unauthorized
      end
    else
      Rails.logger.debug "Authorization header missing"
      render json: { errors: 'Authorization token not found' }, status: :unauthorized
    end
  end    
end