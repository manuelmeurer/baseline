# frozen_string_literal: true

require "baseline/spec/spec_helper"

# Gems that are included in the gemspec, not in the Gemfile,
# are not automatically required.
require "shoulda/matchers"
require "factory_bot_rails"

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
end
