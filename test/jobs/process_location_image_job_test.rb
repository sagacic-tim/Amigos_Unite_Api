require "test_helper"

class ProcessLocationImageJobTest < ActiveJob::TestCase
  queue_as :default

  def perform(event_location)
    # Process the location_image here
    # Example: Resize the image
    event_location.location_image.variant(resize: "640x480").processed
  end
end
