class Api::V1::Amigos::SessionsController < Devise::SessionsController
  include RackSessionsFix
  respond_to :json

  def create
    super do
      Rails.logger.info "Authorization: #{request.headers['Authorization']}"
    end
  end  

  private

  def respond_with(resource, _opts = {})
    render json: {
      status: { 
        code: 200, message: 'Logged in successfully.',
        data: { amigo: AmigoSerializer.new(resource).serializable_hash[:data][:attributes] }
      }
    }, status: :ok
  end

  def respond_to_on_destroy
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
      resource = Amigo.find(jwt_payload['sub'])
    end
    
    if resource
      render json: {
        status: 200,
        message: 'Logged out successfully.'
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end