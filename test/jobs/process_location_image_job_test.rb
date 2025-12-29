# test/jobs/process_location_image_job_test.rb
require "test_helper"
require "stringio"

class ProcessLocationImageJobTest < ActiveJob::TestCase
  test "process_location_image_job runs safely and keeps the image attached" do
    event_location = EventLocation.new(
      business_name: "Test Venue 2",
      address:       "456 Another Street"
    )
    event_location.save!(validate: false)

    event_location.location_image.attach(
      io:          StringIO.new("fake-image-data"),
      filename:    "location-test.png",
      content_type: "image/png"
    )

    assert event_location.location_image.attached?,
           "Precondition: location_image should be attached before the job runs"

    assert_nothing_raised do
      ProcessLocationImageJob.perform_now(event_location.id)
    end

    assert event_location.reload.location_image.attached?,
           "location_image should remain attached after job processing"
  end
end
