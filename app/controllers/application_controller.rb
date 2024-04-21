class ApplicationController < ActionController::API
  include Devise::Controllers::Helpers
  respond_to :json
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[login_attribute])
  
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name user_name email secondary_email phone_1 phone_2 avatar])
    
    devise_parameter_sanitizer.permit(:account_update, keys: %i[first_name last_name user_name email secondary_email phone_1 phone_2 avatar])
  end
  
  def authenticate_amigo!
    puts "authenticate_amigo entered"
    super
    puts "authenticate called on parent class"
  rescue Errno::EACCES
    puts "Insufficient permissions, cannot authenticate amigo."
  end
end