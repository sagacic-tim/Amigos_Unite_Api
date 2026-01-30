# app/mailers/devise_mailer.rb
class DeviseMailer < Devise::Mailer
  # Ensure we inherit your ApplicationMailer defaults (MAIL_FROM, layout, etc.)
  default from: ENV.fetch("MAIL_FROM", "no-replies@amigosunite.org")

  # Force async delivery (Sidekiq via ActiveJob)
  def confirmation_instructions(record, token, opts = {})
    message = super
    message.deliver_later(queue: :mailers)
    message
  end

  def reset_password_instructions(record, token, opts = {})
    message = super
    message.deliver_later(queue: :mailers)
    message
  end

  def unlock_instructions(record, token, opts = {})
    message = super
    message.deliver_later(queue: :mailers)
    message
  end
end
