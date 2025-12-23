# frozen_string_literal: true

Baseline.configuration.async_inline = true

require "rspec/rails"
require "view_component/test_helpers"
require "capybara/rspec"

if defined?(ActiveJob)
  ActiveJob::Base.queue_adapter = :test
end

if defined?(Geocoder)
  Geocoder.configure(lookup: :test)
  Geocoder::Lookup::Test.set_default_stub [{
    "coordinates"  => [52.5170365, 13.3888599],
    "address"      => "Berlin, Germany",
    "state"        => "Berlin",
    "country"      => "Germany",
    "country_code" => "de"
  }]
end

Capybara.configure do |config|
  config.always_include_port = true
  config.server_port         = Rails.application.routes.default_url_options.fetch(:port)
  config.save_path           = Rails.root.join("tmp", "capybara")
end

Capybara.disable_animation = true

Dir[Capybara.save_path.join("*")]
  .select { File.mtime(_1) < 1.month.ago }
  .each { FileUtils.rm _1 }

Capybara.register_driver :my_playwright do |app|
  Capybara::Playwright::Driver.new app,
    playwright_cli_executable_path: "npx playwright@#{Playwright::COMPATIBLE_PLAYWRIGHT_VERSION}",
    headless:                       ENV["HEADLESS"].then { _1.blank? || ActiveRecord::Type::Boolean.new.cast(_1) }
end

Capybara.default_driver =
  Capybara.javascript_driver =
  :my_playwright

Rails
  .root
  .join("spec", "support", "**", "*.rb")
  .then { Dir[_1] }
  .each { require _1 }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.include Baseline::Spec::APIHelpers,      type: :request
  config.include Baseline::Spec::CapybaraHelpers, type: :system

  config.include ViewComponent::TestHelpers,       type: :component
  config.include ViewComponent::SystemSpecHelpers, type: :feature
  config.include ViewComponent::SystemSpecHelpers, type: :system

  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.before :suite do
    Rails.application.load_seed
  end

  config.before :each, type: :system do
    driven_by Capybara.javascript_driver
  end

  config.define_derived_metadata(file_path: %r{spec/components}) do |metadata|
    metadata[:type] = :component
  end

  config.before :each, type: :request do |example|
    file_path = example.metadata[:file_path]

    unless namespace = file_path[%r{spec/requests/([^/]+)/}i, 1]&.to_sym
      raise "Cannot determine namespace from file path: #{file_path}"
    end

    URLManager
      .route_constraints(namespace)
      .fetch_values(:subdomain, :domain)
      .join(".")
      .then {
        host! _1
      }
  end
end
