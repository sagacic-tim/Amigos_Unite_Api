# test/jobs/process_image_job_test.rb
require "test_helper"
require "stringio"

class ProcessImageJobTest < ActiveJob::TestCase
  test "process_image_job runs safely and keeps the image attached" do
    # Create a minimal EventLocation record.
    # We bypass validations to avoid depending on any future changes there.
    event_location = EventLocation.new(
      business_name: "Test Venue",
      address:       "123 Test Street"
    )
    event_location.save!(validate: false)

    # Attach a fake in-memory "image"
    event_location.location_image.attach(
      io:          StringIO.new("fake-image-data"),
      filename:    "test.png",
      content_type: "image/png"
    )

    assert event_location.location_image.attached?,
           "Precondition: location_image should be attached before the job runs"

    # The job should not raise, even if the underlying image processor fails,
    # because perform wraps processing in a rescue.
    assert_nothing_raised do
      ProcessImageJob.perform_now(event_location.id)
    end

    # After running, the record should still have an attached image.
    assert event_location.reload.location_image.attached?,
           "location_image should remain attached after job processing"
  end
end
