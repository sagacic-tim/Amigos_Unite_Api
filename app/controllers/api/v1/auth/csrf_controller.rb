# app/controllers/api/v1/auth/csrf_controller.rb
module Api
  module V1
    module Auth
      class CsrfController < ApplicationController
        skip_before_action :authenticate_amigo!, raise: false

        def show
          session[:_csrf_token] = form_authenticity_token
          Rails.logger.info "Session contents before render: #{session.to_hash.inspect}"
          # force write (usually unnecessary, but for debugging you can try):
          request.session_options[:skip] = false
          cookies['CSRF-TOKEN'] = {
            value:     session[:_csrf_token],
            same_site: :none,
            secure:    true,
            http_only: false
          }
          response.set_header('X-CSRF-Token', session[:_csrf_token])
          head :no_content
        end
      end
    end
  end
end
