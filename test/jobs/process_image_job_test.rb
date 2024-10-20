# require "test_helper"

# class ProcessImageJobTest < ActiveJob::TestCase
# #  queue_as :default

#   def perform(event_location_id)
#     event_location = EventLocation.find(event_location_id)
#     return unless event_location.location_image.attached?

#     resized_image = event_location.location_image.variant(resize: "640x480").processed
#     event_location.location_image.attach(io: File.open(resized_image.path),
#     filename: event_location.location_image.filename.to_s,
#     content_type: event_location.location_image.content_type)
#   end
# end

require "test_helper"

class ProcessImageJobTest < ActiveJob::TestCase
  test "process image job" do
    # Assuming you have a fixture or factory for EventLocation with an attached image
    event_location = event_locations(:one) 

    # Perform the job
    ProcessImageJob.perform_now(event_location.id)

    # Add assertions here to verify the job's behavior
    assert event_location.location_image.attached?
  end
end
