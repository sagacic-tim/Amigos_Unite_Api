class ApplicationMailer < ActionMailer::Base
  default from: "dev@localhost"
  layout "mailer"
end
