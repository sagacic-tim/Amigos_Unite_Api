# app/mailers/contact_mailer.rb

class ContactMailer < ApplicationMailer
  default from: "no-reply@sagacicweb.com"

  def contact_message(first_name:, last_name:, email:, message:)
    @first_name = first_name
    @last_name  = last_name
    @email      = email
    @body_text  = message   # ← rename here

    mail(
      to:        "tmichel@sagacicweb.com",
      reply_to:  email,
      subject:   "New contact from #{@first_name} #{@last_name}"
    )
  end
end

