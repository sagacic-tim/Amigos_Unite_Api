class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  respond_to :json
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :log_request
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[login_attribute])
  
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name user_name email secondary_email phone_1 phone_2 avatar])
    
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name user_name email secondary_email phone_1 phone_2 avatar])
  end
  
  def authenticate_current_user!
    authenticate_amigo! # This is a Devise helper method, tailored for the Amigo model
    puts "Amigo authenticated."
  rescue Errno::EACCES
    puts "Insufficient permissions, cannot authenticate Amigo."
  end

  private

  def log_request
    Rails.logger.info "Incoming request to #{request.path} with headers: #{request.headers.to_h.except('rack.input', 'action_dispatch.secret_key_base', 'action_dispatch.signed_cookie_salt', 'action_dispatch.encrypted_cookie_salt', 'action_dispatch.encrypted_signed_cookie_salt', 'action_dispatch.authenticated_encrypted_cookie_salt', 'action_dispatch.http_auth_salt', 'action_dispatch.secret_token', 'action_dispatch.cookies_serializer', 'action_dispatch.encrypted_cookie_cipher', 'action_dispatch.signed_cookie_cipher', 'action_dispatch.content_security_policy', 'action_dispatch.content_security_policy_nonce_directives', 'action_dispatch.content_security_policy_report_only')}"
  end

end