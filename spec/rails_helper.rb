ENV["RAILS_ENV"] ||= "test"
ENV["LOCKBOX_MASTER_KEY"] ||= "1" * 64

require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
end

Shoulda::Matchers.configure do |matcher_config|
  matcher_config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
