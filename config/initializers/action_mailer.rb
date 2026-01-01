# config/initializers/action_mailer.rb

Rails.application.configure do
  # Base mailer config
  config.action_mailer.perform_deliveries    = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.logger                = Rails.logger

  sendgrid_key = ENV["SENDGRID_API_KEY"]

  if sendgrid_key.present?
    # Normal SMTP configuration when the key is present
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address:              "smtp.sendgrid.net",
      port:                 587,
      domain:               ENV.fetch("MAILER_DOMAIN", "amigosunite.org"),
      user_name:            "apikey", # literal per SendGrid
      password:             sendgrid_key,
      authentication:       :plain,
      enable_starttls_auto: true,
      open_timeout:         15,
      read_timeout:         20
    }

    Rails.logger.info(
      "[MAIL] SendGrid configured (key length=#{sendgrid_key.length}) env=#{Rails.env} pid=#{Process.pid}"
    )
  else
    # No key available
    if Rails.env.production?
      Rails.logger.error "[MAIL] SENDGRID_API_KEY is MISSING in production pid=#{Process.pid}"
      raise "SENDGRID_API_KEY is missing"
    else
      # In development/test, don’t crash the app – just log and disable deliveries.
      config.action_mailer.perform_deliveries = false
      Rails.logger.warn(
        "[MAIL] SENDGRID_API_KEY is missing; skipping SMTP setup and email delivery in #{Rails.env}"
      )
    end
  end
end
