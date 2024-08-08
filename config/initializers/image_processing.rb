# config/initializers/image_processing.rb

Rails.application.reloader.to_prepare do
  require "image_processing/vips" # for libvips

  # Optionally, you can configure ImageProcessing here if needed
  # ImageProcessing::Vips.configure do |config|
  #   config.some_option = some_value
  # end
end  