class ApplicationController < ActionController::API
  include RackSessionsFix
  include Devise::Controllers::Helpers
  include ActionController::Cookies  # Include cookies handling
  include ActionController::RequestForgeryProtection # Include CSRF protection
  
  # Enable CSRF protection
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token
  #skip_before_action :verify_csrf_token, only: [:show]

  before_action :authenticate_amigo!
  # Optional: You can skip CSRF verification for API-only paths
  helper_method :current_amigo
  respond_to :json
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log_request
 
  attr_reader :current_amigo

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [
      :user_name,
      :email,
      :unformatted_phone_1,
      :password
    ])

    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name,
      :last_name,
      :user_name,
      :email,
      :secondary_email,
      :unformatted_phone_1,
      :unformatted_phone_2,
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
      :unformatted_phone_1,
      :unformatted_phone_2,
      :avatar,
      :password,
      :current_password
    ])
  end

  private

  def api_request?
    request.format.json?
  end

  def verify_csrf_token
    csrf_token = request.headers['X-CSRF-Token']
    unless valid_authenticity_token?(session, csrf_token)
      render json: { error: 'Invalid CSRF token' }, status: :unauthorized
    end
  end

  def log_request
    Rails.logger.info "Application Controller - Incoming request to #{request.path} with headers: #{filtered_headers}"
  end

  def filtered_headers
    request.headers.to_h.except(
      'rack.input', 
      'action_dispatch.secret_key_base', 
      'action_dispatch.signed_cookie_salt', 
      'action_dispatch.encrypted_cookie_salt', 
      'action_dispatch.encrypted_signed_cookie_salt', 
      'action_dispatch.authenticated_encrypted_cookie_salt', 
      'action_dispatch.http_auth_salt', 
      'action_dispatch.secret_token', 
      'action_dispatch.cookies_serializer', 
      'action_dispatch.encrypted_cookie_cipher', 
      'action_dispatch.signed_cookie_cipher', 
      'action_dispatch.content_security_policy', 
      'action_dispatch.content_security_policy_nonce_directives', 
      'action_dispatch.content_security_policy_report_only'
    )
  end

  # Authenticate Amigo using only cookies
  def authenticate_amigo!
    token = request.headers['Authorization']&.split(' ')&.last || cookies.signed[:jwt] || cookies.encrypted[:jwt]
    Rails.logger.info "Authenticate Amigo - Token: #{token}"

    if token.present?
      begin
        decoded_token = JsonWebToken.decode(token)
        Rails.logger.info "Authenticate Amigo - Decoded Token: #{decoded_token}"
        @current_amigo = Amigo.find_by(id: decoded_token[:sub])
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_amigo
      rescue JWT::DecodeError => e
        Rails.logger.error "Authenticate Amigo - JWT Decode Error: #{e.message}"
        render json: { error: 'Invalid token' }, status: :unauthorized
      rescue JWT::ExpiredSignature, JWT::VerificationError => e
        Rails.logger.error "Authenticate Amigo - Token Error: #{e.message}"
        render json: { error: 'Token has expired or is invalid' }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "Authenticate Amigo - Amigo Not Found: #{e.message}"
        render json: { error: 'Amigo not found' }, status: :not_found
      end
    else
      Rails.logger.warn "Authenticate Amigo - No JWT Token Provided"
      render json: { error: 'JWT Token missing' }, status: :unauthorized
    end
  end
end