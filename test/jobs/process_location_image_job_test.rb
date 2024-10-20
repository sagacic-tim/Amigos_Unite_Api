# require "test_helper"

# class ProcessLocationImageJobTest < ActiveJob::TestCase
# #  queue_as :default

#   def perform(event_location)
#     # Process the location_image here
#     # Example: Resize the image
#     event_location.location_image.variant(resize: "640x480").processed
#   end
# end

require "test_helper"

class ProcessLocationImageJobTest < ActiveJob::TestCase
  test "process location image job" do
    # Assuming you have a fixture or factory for EventLocation with an attached image
    event_location = event_locations(:one)

    # Perform the job
    ProcessLocationImageJob.perform_now(event_location)

    # Add assertions here to verify the job's behavior
    assert event_location.location_image.attached?
  end
end