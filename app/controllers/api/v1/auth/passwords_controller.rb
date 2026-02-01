# app/controllers/api/v1/auth/passwords_controller.rb
module Api
  module V1
    module Auth
      class PasswordsController < Devise::PasswordsController
        respond_to :json

        # Your ApplicationController has global authenticate_amigo! except public endpoints,
        # so ensure password reset endpoints are treated as public.
        skip_before_action :authenticate_amigo!, raise: false

        # If you enforce CSRF on all mutating requests, keep it consistent:
        # - Either ensure SPA sends CSRF token for this endpoint, OR skip verification here.
        # Given your design ("enforce CSRF for all mutating calls"), DO NOT skip it
        # unless you intentionally want reset requests to be CSRF-free.

        # POST /api/v1/amigos/password (Devise default path helper: amigo_password_path)
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

        # Ensure Devise finds the correct mapping under /api/v1
        def resource_name
          :amigo
        end
      end
    end
  end
end
