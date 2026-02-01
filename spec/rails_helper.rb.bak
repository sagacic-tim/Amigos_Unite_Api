# spec/rails_helper.rb
# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "rspec/rails"

# Load support helpers (AuthHelpers, etc.)
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # ---------------------------------------------------------------------------
  # Test hygiene: mail + jobs
  # ---------------------------------------------------------------------------

  # ActiveJob helpers allow deterministic enqueue assertions and cleanup.
  config.include ActiveJob::TestHelper

  # Ensure mail deliveries do not leak between examples.
  config.before do
    ActionMailer::Base.deliveries.clear
  end

  # Keep enqueued/performed jobs isolated per example.
  # Also executes enqueued jobs so that mail deliveries (and other jobs) occur
  # within the spec process, making assertions reliable.
  config.around do |example|
    perform_enqueued_jobs do
      example.run
    end
  ensure
    clear_enqueued_jobs
    clear_performed_jobs
  end

  # ---------------------------------------------------------------------------
  # Rack::Attack cache reset for request specs
  # ---------------------------------------------------------------------------

  config.before(:each, type: :request) do
    next unless defined?(Rack::Attack)

    cache = Rack::Attack.cache
    store =
      if cache.respond_to?(:store)
        cache.store
      else
        cache
      end

    store.clear if store.respond_to?(:clear)
  end

  # If you keep fixtures temporarily, make them live under spec/fixtures.
  # If you do not use fixtures (recommended), this is harmless.
  config.fixture_paths = ["#{::Rails.root}/spec/fixtures"]

  config.use_transactional_fixtures = true

  config.include FactoryBot::Syntax::Methods
  config.include AuthHelpers, type: :request

  config.include Rails.application.routes.url_helpers

  config.before(type: :request) do
    host! "localhost"
  end

  # RSpec-only: load factories from spec/factories
  config.before(:suite) do
    FactoryBot.definition_file_paths = [Rails.root.join("spec/factories")]
    FactoryBot.reload
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
