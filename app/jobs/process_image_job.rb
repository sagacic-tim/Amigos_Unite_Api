# Part of ImageMagic and the mini_magick gem.
# Resizes uploaded imaged to 640 x 480 pixels

class ProcessImageJob < ApplicationJob
  queue_as :default

  def perform(event_location_id)
    event_location = EventLocation.find(event_location_id)
    return unless event_location.location_image.attached?

    resized_image = event_location.location_image.variant(resize: "640x480").processed
    event_location.location_image.attach(io: File.open(resized_image.path), filename: event_location.location_image.filename.to_s, content_type: event_location.location_image.content_type)
  end
end