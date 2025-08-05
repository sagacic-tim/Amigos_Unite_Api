class ApplicationController < ActionController::API
  include RackSessionsFix
  include Devise::Controllers::Helpers
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  include Authentication

  # ensure Devise sees our JSON‑API signup/login routes as the :amigo mapping
  prepend_before_action :force_devise_amigo_mapping

  # keep the session alive, but skip Rails's default param-based check on API calls
  protect_from_forgery with: :exception
  # skip_before_action :verify_authenticity_token, if: :api_request?

  # only issue a fresh CSRF‑TOKEN cookie on GETs (or other safe HTTP verbs)
  before_action :set_csrf_cookie,  if: -> { api_request? && request.get? }
  # verify but don’t clobber the token on mutating requests
  before_action :verify_csrf_token, if: -> { api_request? && request.method.in?(%w[POST PUT PATCH DELETE]) }

  before_action :authenticate_amigo!
  helper_method :current_amigo
  respond_to :json
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log_request

  attr_reader :current_amigo

  def options_request
    head :ok
  end

  protected

  # Issue CSRF token cookie for frontend use
  def set_csrf_cookie
    cookies['CSRF-TOKEN'] = {
      value:     form_authenticity_token,
      same_site: Rails.env.development? ? :none : :strict,
      secure:    true,    # <— must be true when same_site is :none (since you're on HTTPS)
      http_only: false
    }
  end

  # Custom CSRF token verification from header
  def verify_csrf_token
    header = request.headers['X-CSRF-Token']
    unless header.present? && valid_authenticity_token?(session, header)
      Rails.logger.error "CSRF token mismatch. Received: #{header.inspect}"
      render json: { error: 'Invalid CSRF token' }, status: :unauthorized
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[
      user_name email unformatted_phone_1 password
    ])

    devise_parameter_sanitizer.permit(:sign_up, keys: %i[
      first_name last_name user_name email secondary_email
      unformatted_phone_1 unformatted_phone_2 avatar password password_confirmation
    ])

    devise_parameter_sanitizer.permit(:account_update, keys: %i[
      first_name last_name user_name email secondary_email
      unformatted_phone_1 unformatted_phone_2 avatar password current_password
    ])
  end

  private

  # For any of our custom Devise endpoints under /api/v1, force the mapping
  def force_devise_amigo_mapping
    if request.path.start_with?("/api/v1/") &&
       %w[signup login refresh_token logout verify_token].any? { |segment|
         request.path.include?(segment)
       }
      Rails.logger.info "[APPLICATION] forcing Devise.mapping[:amigo] for #{request.path}"
      request.env["devise.mapping"] = Devise.mappings[:amigo]
    end
    puts "force map complete"
  end
  def api_request?
    request.format.json? || request.path.start_with?('/api')
  end

  def log_request
    Rails.logger.info "API Request to #{request.path} with headers: #{filtered_headers}"
  end

  def filtered_headers
    request.headers.to_h.except(
      *%w[
        rack.input action_dispatch.secret_key_base
        action_dispatch.signed_cookie_salt action_dispatch.encrypted_cookie_salt
        action_dispatch.encrypted_signed_cookie_salt action_dispatch.authenticated_encrypted_cookie_salt
        action_dispatch.http_auth_salt action_dispatch.secret_token
        action_dispatch.cookies_serializer action_dispatch.encrypted_cookie_cipher
        action_dispatch.signed_cookie_cipher action_dispatch.content_security_policy
        action_dispatch.content_security_policy_nonce_directives
        action_dispatch.content_security_policy_report_only
      ]
    )
  end

  def authenticate_amigo!
    token = extract_jwt_token
    Rails.logger.info "Authenticating with token: #{token&.slice(0, 15)}..."

    if token.present?
      begin
        decoded = JsonWebToken.decode(token)
        @current_amigo = Amigo.find(decoded[:sub])
      rescue JWT::DecodeError => e
        Rails.logger.warn "JWT decode error: #{e.message}"
        render json: { error: 'Invalid token' }, status: :unauthorized
      rescue JWT::ExpiredSignature, JWT::VerificationError => e
        Rails.logger.warn "JWT expired or invalid: #{e.message}"
        render json: { error: 'Token has expired or is invalid' }, status: :unauthorized
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.warn "Amigo not found: #{e.message}"
        render json: { error: 'Amigo not found' }, status: :not_found
      end
    else
      Rails.logger.warn "JWT token missing"
      render json: { error: 'JWT token missing' }, status: :unauthorized
    end
  end

  def extract_jwt_token
    request.headers['Authorization']&.split(' ')&.last ||
      cookies.signed[:jwt] ||
      cookies.encrypted[:jwt]
  end
end
