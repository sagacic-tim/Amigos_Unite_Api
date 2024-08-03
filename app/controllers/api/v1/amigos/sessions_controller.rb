module Api
  module V1
    module Amigos
      class SessionsController < Devise::SessionsController
        include ActionController::MimeResponds
        include ActionController::Cookies
        respond_to :json

        def create
          amigo = Amigo.find_for_database_authentication(login_attribute: params[:amigo][:login_attribute])

          if amigo&.valid_password?(params[:amigo][:password])
            payload = {
              sub: amigo.id,  # User ID
              exp: 24.hours.from_now.to_i,
              jti: SecureRandom.uuid  # Unique token ID
            }
            token = JsonWebToken.encode(payload)
            Rails.logger.info "SessionsController - Generated token: #{token}" # Debugging line
            cookies.signed[:jwt] = { value: token, httponly: true, expires: 24.hours.from_now }

            render json: {
              status: {
                code: 200,
                message: 'Logged into Amigos Unite successfully.',
                data: {
                  amigo: AmigoSerializer.new(amigo).serializable_hash[:data][:attributes],
                  jwt: token
                }
              }
            }, status: :ok
          else
            render json: {
              status: {
                code: 401,
                message: 'Login failed'
              }
            }, status: :unauthorized
          end
        end

        def destroy
          token = cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last
          Rails.logger.info "SessionsController - Token received for logout: #{token}" # Debugging line

          decoded_token = JsonWebToken.decode(token)
          if decoded_token[:error].present?
            render json: { status: 401, message: 'Invalid token' }, status: :unauthorized
          else
            JWTDenylist.add(token)
            cookies.delete(:jwt)
            render json: { status: 200, message: 'Logged out of Amigos Unite successfully.' }, status: :ok
          end
        rescue JWT::DecodeError => e
          render json: { status: 401, message: e.message }, status: :unauthorized
        end

        protected

        def respond_to_on_destroy
          # This method can be used if you want to override the default response when destroying a session
        end
      end
    end
  end
end