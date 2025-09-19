# frozen_string_literal: true
module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController

        include RackSessionsFix
        respond_to :json

        # POST /api/v1/signup
        def create
          super
        end

        private

        # Permit only the fields you need for signup
        def sign_up_params
          params.require(:amigo).permit(:email, :password)
        end

        # Customize the JSON + cookie response
        def respond_with(resource, _opts = {})
          if resource.persisted?
            # 1) Issue JWT
            jwt = Warden::JWTAuth::UserEncoder.new
                                       .call(resource, :amigo, nil)
                                       .first
            cookies.signed[:jwt] = {
              value:      jwt,
              httponly:   true,
              secure:     Rails.env.production?,
              same_site:  :lax
            }

            # 2) Expose CSRF token so Axios can pick it up
            cookies['CSRF-TOKEN'] = {
              value:      form_authenticity_token,
              secure:     Rails.env.production?,
              same_site:  :lax
            }

            # 3) Render JSON payload
            render json: {
              status: { code: 200, message: 'Signed up successfully. Welcome, Amigo!' },
              data:   { amigo: AmigoSerializer
                               .new(resource)
                               .serializable_hash[:data][:attributes] }
            }, status: :ok
          else
            render json: {
              status: {
                code:    422,
                message: 'Signup failed.',
                errors:  resource.errors.messages
              }
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
