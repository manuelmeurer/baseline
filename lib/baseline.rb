# frozen_string_literal: true

module Baseline
  NULL_VALUE = "_null_value_".freeze

  autoload :ControllerExtensions, "baseline/controller_extensions"
  autoload :ExternalService,      "baseline/external_service"
  autoload :Helper,               "baseline/helper"
  autoload :ModelExtensions,      "baseline/model_extensions"
  autoload :NamespaceLayout,      "baseline/namespace_layout"
  autoload :RedisURL,             "baseline/redis_url"
  autoload :ReportError,          "baseline/report_error"
  autoload :Service,              "baseline/service"
  autoload :StimulusController,   "baseline/stimulus_controller"

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
  end
end

require "baseline/configuration"
require "baseline/if_unless"
require "baseline/deep_fetch"

# Initialize configuration
Baseline.configuration

if defined?(Rails)
  require "baseline/railtie"

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
  end
end
