
# test/mailers/previews/contact_mailer_preview.rb (or spec/mailers/previews)
class ContactMailerPreview < ActionMailer::Preview
  def contact_message
    ContactMailer.contact_message(
      first_name: "Ada",
      last_name:  "Lovelace",
      email:      "ada@example.com",
      message:    "Hello! This is a test message.\nSecond line."
    )
  end
end
