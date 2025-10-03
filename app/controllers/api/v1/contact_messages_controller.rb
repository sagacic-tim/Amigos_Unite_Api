# app/controllers/api/v1/contact_messages_controller.rb
class Api::V1::ContactMessagesController < ApplicationController
  # If you have an auth filter globally:
  skip_before_action :authenticate_amigo!, only: :create

  # If your API still verifies CSRF for JSON posts, either:
  # Option 1: use null_session for APIs (preferred in API-only)
  protect_from_forgery with: :null_session, only: :create

  # OR Option 2 (less ideal): skip verification just for this endpoint
  # skip_before_action :verify_authenticity_token, only: :create

  def create
    p = params.require(:contact_message).permit(:first_name, :last_name, :email, :message)

    ContactMailer.contact_message(
      first_name: p[:first_name],
      last_name:  p[:last_name],
      email:      p[:email],
      message:    p[:message]
    ).deliver_later

    render json: { ok: true }
  end
end
