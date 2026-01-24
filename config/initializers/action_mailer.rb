# config/initializers/action_mailer.rb

Rails.application.configure do
  # Boot-safe logger: Rails.logger may not be initialized yet here.
  boot_logger =
    if config.respond_to?(:logger) && config.logger
      config.logger
    else
      ActiveSupport::Logger.new($stdout)
    end

  # Keep Action Mailer logging pointed somewhere sane (avoid Rails.logger directly).
  config.action_mailer.logger = boot_logger

  sendgrid_key = ENV["SENDGRID_API_KEY"].to_s.strip
  sendgrid_enabled = sendgrid_key.present?

  # If SendGrid is not configured, disable deliveries rather than failing boot.
  config.action_mailer.perform_deliveries = sendgrid_enabled

  # Do not raise delivery errors by default; opt-in with MAIL_RAISE_DELIVERY_ERRORS=true
  config.action_mailer.raise_delivery_errors =
    sendgrid_enabled && ENV.fetch("MAIL_RAISE_DELIVERY_ERRORS", "false") == "true"

  if sendgrid_enabled
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

    boot_logger.info("[mail] SendGrid SMTP configured env=#{Rails.env} pid=#{Process.pid}")
  else
    # Log, but never crash boot.
    boot_logger.warn("[mail] SENDGRID_API_KEY missing; email delivery disabled env=#{Rails.env} pid=#{Process.pid}")
  end
end
