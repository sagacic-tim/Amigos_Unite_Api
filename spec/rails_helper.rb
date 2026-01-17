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
