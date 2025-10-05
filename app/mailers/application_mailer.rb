# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: 'tmichel@sagacicweb.com'
  layout 'mailer'  # make sure this is present
end
