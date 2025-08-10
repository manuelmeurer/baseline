lib = File.expand_path("../lib", __FILE__)

unless $LOAD_PATH.include?(lib)
  $LOAD_PATH.unshift(lib)
end

require_relative "lib/baseline/version"

Gem::Specification.new do |gem|
  files      = `git ls-files`.split($/)
  test_files = files.grep(%r{^spec/})

  gem.name                  = "baseline"
  gem.version               = Baseline::VERSION
  gem.platform              = Gem::Platform::RUBY
  gem.author                = "Manuel Meurer"
  gem.email                 = "manuel@meurer.io"
  gem.summary               = "Baseline"
  gem.description           = "Baseline"
  gem.homepage              = "https://github.com/manuelmeurer/baseline"
  gem.license               = "MIT"
  gem.required_ruby_version = ">= 3.1"
  gem.files                 = files - test_files
  gem.executables           = gem.files.grep(%r{\Abin/}).map(&File.method(:basename))
  gem.test_files            = test_files
  gem.require_paths         = ["lib"]

  gem.add_dependency "zeitwerk"
  gem.add_development_dependency "rubocop-rails-omakase", "~> 1.1"
end
