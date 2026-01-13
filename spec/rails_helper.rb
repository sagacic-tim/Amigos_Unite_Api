# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "spec_helper"
require "rspec/rails"

# Load files in spec/support (AuthHelpers lives here)
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Ensures schema is up to date when running specs locally.
# In CI you already run db:schema:load, so this should be fast/no-op.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # If you use fixtures, keep this. If not, you can remove.
  config.fixture_path = "#{::Rails.root}/test/fixtures"

  config.use_transactional_fixtures = true

  # FactoryBot shorthand: create(), build(), etc.
  config.include FactoryBot::Syntax::Methods

  # Include your helper for request specs
  config.include AuthHelpers, type: :request

  # Typical Rails/RSpec settings
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
