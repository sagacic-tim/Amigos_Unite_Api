# config/initializers/action_mailer.rb
Rails.application.configure do
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              "smtp.sendgrid.net",
    port:                 587,
    domain:               "sagacicweb.com",
    user_name:            "apikey", # literal per SendGrid
    password:             ENV["SENDGRID_API_KEY"],          # ← use ENV
    authentication:       :plain,
    enable_starttls_auto: true,
    open_timeout:         15,
    read_timeout:         20
  }

  # Optional logging + hard fail if missing to avoid silent worker errors
  config.action_mailer.logger = Rails.logger
  if ENV["SENDGRID_API_KEY"].to_s.empty?
    Rails.logger.error "[MAIL] SENDGRID_API_KEY is MISSING in pid=#{Process.pid}"
    raise "SENDGRID_API_KEY is missing"
  else
    Rails.logger.warn "[MAIL] SENDGRID_API_KEY PRESENT len=#{ENV['SENDGRID_API_KEY'].length} pid=#{Process.pid}"
  end
end
