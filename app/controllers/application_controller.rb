class ApplicationController < ActionController::API
  include RackSessionsFix
  include Devise::Controllers::Helpers
  include ActionController::Cookies  # Include cookies handling
  helper_method :current_amigo
  respond_to :json
  #before_action :authenticate_amigo!, only: [:show, :update, :destroy]
  before_action :authenticate_amigo!
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

  # # Authenticate Amigo using only cookies
  # def authenticate_amigo!
  #   token = cookies.signed[:jwt] # Only check cookies for the JWT token
  #   if token.present?
  #     begin
  #       decoded_token = JsonWebToken.decode(token)
  #       @current_amigo = Amigo.find(decoded_token[:sub])
  #       unless @current_amigo
  #         render json: { error: 'Unauthorized' }, status: :unauthorized
  #       end
  #     rescue JWT::DecodeError => e
  #       render json: { error: 'Authentication failed.' }, status: :unauthorized
  #     rescue JWT::ExpiredSignature, JWT::VerificationError => e
  #       render json: { error: 'Token has expired or is invalid' }, status: :unauthorized
  #     end
  #   else
  #     render json: { error: 'Authentication failed.' }, status: :unauthorized
  #   end
  # end

  def authenticate_amigo!
    token = request.headers['Authorization']&.split(' ')&.last
    if token
      decoded_token = JsonWebToken.decode(token)
      @current_amigo = Amigo.find_by(id: decoded_token[:sub])
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end