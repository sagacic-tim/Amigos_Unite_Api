# config/initializers/image_processing.rb

# Load and configure the ImageProcessing gem with libvips
Rails.application.reloader.to_prepare do
  begin
    require "image_processing/vips"

    # Optional: Custom configuration placeholder
    # ImageProcessing::Vips.configure do |config|
    #   config.some_option = some_value
    # end

    Rails.logger.info "[ImageProcessing] libvips loaded successfully"
  rescue LoadError => e
    Rails.logger.warn "[ImageProcessing] libvips not loaded: #{e.message}"
  end
end
