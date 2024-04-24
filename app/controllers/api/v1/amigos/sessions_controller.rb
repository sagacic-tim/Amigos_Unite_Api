module Api
  module V1
    module Amigos
      class SessionsController < Devise::SessionsController
        include RackSessionsFix
        respond_to :json

        def create
          super do |resource|
            @token = current_token
            # This block only executes if login was successful
          end
        end

        def destroy
          super do
            # This block only executes if logout was successful
          end
        end

        protected

        def respond_with(resource, _opts = {})
          if resource.persisted?
            render json: {
              status: {
                code: 200, 
                message: 'Logged into Amigos Unite successfully.',
                data: {
                  amigo: AmigoSerializer.new(resource).serializable_hash[:data][:attributes],
                  jwt: @token
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

        def respond_to_on_destroy
          render json: {
            status: 200,
            message: 'Logged out of Amigos Unite successfully.'
          }, status: :ok
        end

         # Method to fetch the current JWT token from the Warden environment
        def current_token
          request.env['warden-jwt_auth.token']
        end
      end
    end
  end
end