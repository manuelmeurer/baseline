# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("dummy/config/environment", __dir__)

require "rspec/rails"
require "view_component/test_helpers"
require "shoulda/matchers"
require "factory_bot_rails"

Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{spec/components}) do |metadata|
    metadata[:type] = :component
  end

  config.include ViewComponent::TestHelpers,       type: :component
  config.include ViewComponent::SystemSpecHelpers, type: :feature
  config.include ViewComponent::SystemSpecHelpers, type: :system
  config.include FactoryBot::Syntax::Methods

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before :suite do
    unless ENV["SKIP_ASSETS_PRECOMPILE"]
      puts "Precompiling assets..."
      system("
        cd spec/dummy &&
          bin/rails dartsass:build &&
          bin/rails assets:precompile
      ") ||
        raise("Asset precompilation failed")
    end
  end

  config.before :each, type: :request do
    host! Rails.application.env_credentials.host!
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
