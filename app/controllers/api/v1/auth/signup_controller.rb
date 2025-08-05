
# app/controllers/api/v1/auth/signup_controller.rb
module Api
  module V1
    module Auth
      class SignupController < ApplicationController
        # skip_before_action :authenticate_amigo!      # no JWT required
       # skip_before_action :verify_csrf_token, only: [:create] # or remove if your CSRF setup already handles it

        # POST /api/v1/signup
        def create
          amigo = Amigo.new(sign_up_params)
          if amigo.save
            # 1) Issue JWT
            jwt = Warden::JWTAuth::UserEncoder.new.call(amigo, :amigo, nil).first
            cookies.signed[:jwt] = {
              value:      jwt,
              httponly:   true,
              secure:     Rails.env.production?,
              same_site:  :lax
            }

            # 2) Expose CSRF token
            cookies['CSRF-TOKEN'] = {
              value:     form_authenticity_token,
              same_site: :lax,
              secure:    Rails.env.production?,
              http_only: false
            }

            # 3) Render JSON
            render json: {
              status: { code: 200, message: 'Signed up successfully. Welcome, Amigo!' },
              data:   { amigo: AmigoSerializer.new(amigo).serializable_hash }
            }, status: :ok

          else
            render json: {
              status: {
                code:    422,
                message: 'Signup failed.',
                errors:  amigo.errors.messages
              }
            }, status: :unprocessable_entity
          end
        end

        private

        def sign_up_params
          params.require(:amigo).permit(:first_name, :last_name, :user_name,
                                        :email, :password, :password_confirmation)
        end
      end
    end
  end
end
