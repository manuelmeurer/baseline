# frozen_string_literal: true

require "zeitwerk"
require_relative "baseline/inflector"

loader = Zeitwerk::Loader.for_gem

loader.ignore("#{__dir__}/baseline/environments")
loader.ignore("#{__dir__}/baseline/initializers")
loader.ignore("#{__dir__}/baseline/monkeypatches.rb")
loader.ignore("#{__dir__}/baseline/services/external")
loader.ignore("#{__dir__}/baseline/sitemap_generator.rb")

unless defined?(::Avo)
  loader.ignore("#{__dir__}/baseline/avo")
end

loader.collapse("#{__dir__}/baseline/components")
loader.collapse("#{__dir__}/baseline/controller_concerns")
loader.collapse("#{__dir__}/baseline/model_concerns")
loader.collapse("#{__dir__}/baseline/service_concerns")
loader.collapse("#{__dir__}/baseline/services")

loader.inflector = Baseline::Inflector.new(__FILE__)

loader.setup

module Baseline
  NOT_SET = Object.new.freeze

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

    def load_thor_tasks
      path = File.expand_path(__dir__)
      Dir
        .glob("#{path}/baseline/tasks/**/*.thor")
        .each {
          load _1
        }
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
      images_path = Rails.root.join("app", "assets", "images")
      cache_key = [
        :image_assets,
        Rails.configuration.revision,
        dir
      ]
      Rails.cache.fetch cache_key, force: Rails.env.development? do
        Rails
          .application
          .assets
          .reveal
          .select { _1.to_s.start_with? dir }
          .sort
          .map(&:to_s)
      end.index_with {
        File.open(images_path.join(_1))
      }
    end
  end
end
