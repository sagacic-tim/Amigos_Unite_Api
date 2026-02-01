# app/controllers/api/v1/auth/passwords_controller.rb
module Api
  module V1
    module Auth
      class PasswordsController < Devise::PasswordsController
        respond_to :json

        # Password reset is a public endpoint
        skip_before_action :authenticate_amigo!, raise: false

        # Your ApplicationController enforces CSRF for ALL mutating API calls.
        # The spec sets CSRF cookie + header, so we KEEP CSRF verification enabled.
        # (Do NOT skip verify_csrf_token here.)

        # POST /api/v1/amigos/password (helper: amigo_password_path)
        def create
          self.resource = resource_class.send_reset_password_instructions(resource_params)

          if successfully_sent?(resource)
            render json: {
              status: { code: 200, message: "Reset password instructions sent." }
            }, status: :ok
          else
            render json: {
              status: {
                code: 422,
                message: "Unable to send reset instructions.",
                errors: resource.errors.full_messages
              }
            }, status: :unprocessable_entity
          end
        end

        protected

        # Ensure Devise mapping is correct for API namespace
        def resource_name
          :amigo
        end

        # Devise expects params under :amigo for password reset
        def resource_params
          params.require(:amigo).permit(:email)
        end
      end
    end
  end
end
