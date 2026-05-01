# frozen_string_literal: true

require "zeitwerk"
require_relative "baseline/inflector"

loader = Zeitwerk::Loader.for_gem

loader.ignore("#{__dir__}/baseline/environments")
loader.ignore("#{__dir__}/baseline/errors.rb")
loader.ignore("#{__dir__}/baseline/errors")
loader.ignore("#{__dir__}/baseline/jobs.rb")
loader.ignore("#{__dir__}/baseline/jobs")
loader.ignore("#{__dir__}/baseline/admin")
loader.ignore("#{__dir__}/baseline/initializers")
loader.ignore("#{__dir__}/baseline/monkeypatches.rb")
loader.ignore("#{__dir__}/baseline/services/external")
loader.ignore("#{__dir__}/baseline/dummies")
loader.ignore("#{__dir__}/baseline/sitemap_generator.rb")
loader.ignore("#{__dir__}/baseline/strict_ivars.rb")
loader.ignore("#{__dir__}/baseline/spec/rails_helper.rb")
loader.ignore("#{__dir__}/baseline/spec/spec_helper.rb")
loader.ignore("#{__dir__}/active_job")
loader.ignore("#{__dir__}/active_storage")
loader.ignore("#{__dir__}/generators")

unless defined?(::Avo)
  loader.ignore("#{__dir__}/baseline/avo")
  loader.ignore("#{__dir__}/baseline/components/avo")
end

loader.collapse("#{__dir__}/baseline/components")
loader.collapse("#{__dir__}/baseline/controller_concerns")
loader.collapse("#{__dir__}/baseline/model_concerns")
loader.collapse("#{__dir__}/baseline/service_concerns")
loader.collapse("#{__dir__}/baseline/services")

loader.inflector = Baseline::Inflector.new(__FILE__)

# `Baseline::Admin` (Rails engine) and `Baseline::Errors` both have code in
# both `app/*` (managed by `Rails.autoloaders.main`) and `lib/baseline/*`.
# If this gem's (reloading) loader managed the `lib/` side, reloading would
# replace the module objects, invalidating rails.main's crefs and breaking
# autoload of constants under `app/*`. Define the namespaces here and
# manage their `lib/` children with separate, non-reloading loaders.
module Baseline
  module Errors
  end

  module Jobs
  end

  module Admin
  end
end

errors_loader = Zeitwerk::Loader.new
errors_loader.tag = "baseline.errors"
errors_loader.inflector = Baseline::Inflector.new(__FILE__)
errors_loader.push_dir("#{__dir__}/baseline/errors", namespace: Baseline::Errors)
errors_loader.setup
require_relative "baseline/errors"

jobs_loader = Zeitwerk::Loader.new
jobs_loader.tag = "baseline.jobs"
jobs_loader.inflector = Baseline::Inflector.new(__FILE__)
jobs_loader.push_dir("#{__dir__}/baseline/jobs", namespace: Baseline::Jobs)
jobs_loader.setup
require_relative "baseline/jobs"

admin_loader = Zeitwerk::Loader.new
admin_loader.tag = "baseline.admin"
admin_loader.inflector = Baseline::Inflector.new(__FILE__)
admin_loader.push_dir("#{__dir__}/baseline/admin", namespace: Baseline::Admin)
admin_loader.setup

if defined?(Rails) && Rails.env.development?
  loader.enable_reloading
end

loader.setup

module Baseline
  NOT_SET = Object.new.freeze
  ALL     = Object.new.freeze

  class << self
    def has_many_reflection_classes
      [
        ActiveRecord::Reflection::HasManyReflection,
        ActiveRecord::Reflection::HasAndBelongsToManyReflection,
        ActiveRecord::Reflection::ThroughReflection
      ]
    end

    def fetch_asset_host_manifests
      return unless asset_host = Rails.application.config.asset_host
      return if ENV["SKIP_FETCH_ASSET_HOST_MANIFESTS"]

      require "http"

      path     = File.join("assets", ".manifest.json")
      content  = HTTP.get("#{asset_host}/#{path}").then { _1.body.to_s if _1.status.success? }
      pathname = Rails.root.join("public", path)

      FileUtils.mkdir_p pathname.dirname
      File.write pathname, content
    end

    def load_worktree_manager_env
      return unless ENV["CONDUCTOR_ROOT_PATH"] || ENV["SUPERSET_ROOT_PATH"]

      env_file = ".env.worktree-manager"

      unless File.exist?(env_file)
        port =
          if ENV["CONDUCTOR_ROOT_PATH"]
            "$CONDUCTOR_PORT"
          else
            # Superset doesn't expose a per-workspace port like Conductor's CONDUCTOR_PORT, so we pick one ourselves.
            # Passing 0 to TCPServer asks the kernel for a free port from its ephemeral range (49152–65535 on macOS);
            # we close immediately and bake the number into the env file so it stays stable across restarts.
            require "socket"
            server = TCPServer.new("127.0.0.1", 0)
            server.addr[1].tap { server.close }
          end

        File.write env_file, <<~CONTENT
          PORT=#{port}
        CONTENT
      end

      Dotenv::Rails.overwrite = true
      Dotenv::Rails.files.unshift(env_file)
    end

    def load_thor_tasks
      path = File.expand_path(__dir__)
      Dir
        .glob("#{path}/baseline/tasks/**/*.thor")
        .each {
          load _1
        }
    end

    def ensure_playwright_chromium_installed!
      require "playwright"
      system("npx playwright@#{::Playwright::COMPATIBLE_PLAYWRIGHT_VERSION} install chromium")
    end

    def dummy(ext)
      File
        .join(__dir__, "baseline", "dummies", "dummy.#{ext}")
        .tap { raise "Dummy file not found: #{_1}" unless File.exist?(_1) }
    end

    def load_initializer(identifier, **kwargs)
      kwargs.each {
        instance_variable_set("@#{_1}", _2)
      }
      File
        .join(__dir__, "baseline/initializers/#{identifier}.rb")
        .then { File.read _1 }
        .then { instance_eval _1 }
    end
  end
end

require "baseline/configuration"
require "baseline/monkeypatches"

# Initialize configuration
Baseline.configuration

if defined?(Rails)
  require "baseline/engine"
  require "baseline/admin/engine"

  Rails::Application.class_eval do
    def env_credentials(env = Rails.env)
      @env_credentials ||= {}
      @env_credentials[env] ||= begin
        creds = credentials.dup
        env_creds = creds.delete(:"__#{env}")
        creds.delete_if { _1.start_with?("__") }
        creds.deep_merge(env_creds || {})
      end
    end

    def image_assets(dir)
      dir += "/" unless dir.end_with?("/")
      root =
        dir.split("/").first == "baseline" ?
          Baseline::Engine.root :
          Rails.root
      images_path = root.join("app", "assets", "images")
      cache_key = [
        :image_assets,
        Rails.configuration.revision,
        dir
      ]

      Rails.cache.fetch(cache_key, force: Rails.env.development?) do
        Rails
          .application
          .assets
          .reveal
          .select { _1.to_s.start_with?(dir) }
          .sort
          .map(&:to_s)
      end.index_with {
        File.open(images_path.join(_1))
      }
    end
  end
end
