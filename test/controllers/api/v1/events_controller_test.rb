# test/controllers/api/v1/events_controller_test.rb
require "test_helper"

module Api
  module V1
    class EventsControllerTest < ActionDispatch::IntegrationTest
      test "index returns success and a JSON:API-style payload" do
        # Hit the literal path instead of a route helper
        get "/api/v1/events", as: :json
        assert_response :success

        body = JSON.parse(@response.body)

        # JSON:API-style payload: top-level Hash with "data" array
        assert_kind_of Hash, body
        assert body.key?("data"), "Expected top-level 'data' key"
        assert_kind_of Array, body["data"]
      end

      test "show returns not_found for a non-existent event" do
        # Use an ID that should not exist
        get "/api/v1/events/999_999", as: :json
        assert_response :not_found

        body = JSON.parse(@response.body)
        # Matches your handle_standard_error implementation
        assert_equal "Event with ID 999_999 does not exist.", body["error"]
      end
    end
  end
end
