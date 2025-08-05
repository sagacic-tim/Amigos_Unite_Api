
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_amigo!
    helper_method :current_amigo
  end

  private

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

  def current_amigo
    @current_amigo
  end
end

  def require_authentication!
    unless current_amigo
      Rails.logger.warn "Authentication required but missing current_amigo"
      render json: { error: 'Authentication required' }, status: :unauthorized
    end
  end

  def admin_only!
    unless current_amigo&.admin?
      Rails.logger.warn "Unauthorized admin access attempt by: #{current_amigo&.user_name || 'guest'}"
      render json: { error: 'Admin access required' }, status: :forbidden
    end
  end
