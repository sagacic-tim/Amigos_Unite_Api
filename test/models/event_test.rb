# test/models/event_test.rb
require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "factory is valid" do
    event = build(:event)
    assert event.valid?, event.errors.full_messages.to_sentence
  end

  test "requires lead_coordinator" do
    event = build(:event, lead_coordinator: nil)
    assert_not event.valid?
    assert_includes event.errors[:lead_coordinator], "must exist"
  end

  test "default status is planning" do
    event = create(:event)
    # adjust if your enum naming differs
    assert_equal "planning", event.status
  end
end

