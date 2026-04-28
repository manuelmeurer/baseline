# frozen_string_literal: true

require "baseline/spec/spec_helper"

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("dummy/config/environment", __dir__)

require "baseline/spec/rails_helper"

# Explicitly configure FactoryBot to load factories from spec/factories
# since the baseline engine structure is non-standard.
FactoryBot.definition_file_paths = [
  File.expand_path("factories", __dir__)
]
FactoryBot.find_definitions

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
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

  config.before(:each, :avo) do
    skip "Avo gem is not loaded in the dummy app" unless defined?(::Avo)
  end
end
