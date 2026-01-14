# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "rspec/rails"

# Load files in spec/support (AuthHelpers lives here)
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Ensures schema is up to date when running specs locally.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Rails 7.1 deprecation: fixture_paths should be an array
  config.fixture_paths = ["#{::Rails.root}/test/fixtures"]

  config.use_transactional_fixtures = true

  # FactoryBot shorthand: create(), build(), etc.
  config.include FactoryBot::Syntax::Methods

  # Request helpers (auth + csrf helpers)
  config.include AuthHelpers, type: :request

  # Route helpers (useful generally; note your scoped /api/v1 routes will NOT be api_v1_* named)
  config.include Rails.application.routes.url_helpers

  # Give request specs a default host (helps some url generation + integration behavior)
  config.before(type: :request) do
    host! "localhost"
  end

  # IMPORTANT:
  # You already have comprehensive factories under test/factories.
  # If you also have spec/factories, you can get duplicate definition errors.
  #
  # This forces FactoryBot to load only from test/factories by default.
  # If you *want* spec/factories too, add Rails.root.join("spec/factories") to the array.
  config.before(:suite) do
    FactoryBot.definition_file_paths = [Rails.root.join("test/factories")]
    FactoryBot.reload
  end

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
