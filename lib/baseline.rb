# frozen_string_literal: true

module Baseline
  NULL_VALUE = "_null_value_".freeze

  # Controller concerns
  autoload :ControllerCore,         "baseline/controller_concerns/controller_core"
  autoload :I18nScopes,             "baseline/controller_concerns/i18n_scopes"
  autoload :NamespaceLayout,        "baseline/controller_concerns/namespace_layout"

  # Model concerns
  autoload :HasLocale,              "baseline/model_concerns/has_locale"
  autoload :HasTimestamps,          "baseline/model_concerns/has_timestamps"
  autoload :ModelCore,              "baseline/model_concerns/model_core"
  autoload :SaveSlugIdentifier,     "baseline/model_concerns/save_slug_identifier"

  # Services
  autoload :BaseService,            "baseline/services/base_service"
  autoload :DownloadFile,           "baseline/services/download_file"
  autoload :ExternalService,        "baseline/services/external_service"
  autoload :MarkdownToHTML,         "baseline/services/markdown_to_html"
  autoload :ReportError,            "baseline/services/report_error"
  autoload :UpdateSchemaMigrations, "baseline/services/update_schema_migrations"

  module External
    autoload :Lexoffice,            "baseline/services/external/lexoffice"
  end
  module Recurring
    autoload :Base,                 "baseline/services/recurring/base"
  end

  # Components
  autoload :FormFieldComponent,     "baseline/components/form_field_component"

  autoload :ApplicationCore,        "baseline/application_core"
  autoload :Helper,                 "baseline/helper"
  autoload :RedisURL,               "baseline/redis_url"
  autoload :StimulusController,     "baseline/stimulus_controller"

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

require "baseline/engine"
require "baseline/configuration"
require "baseline/object_helpers"
require "baseline/deep_fetch"

# Initialize configuration
Baseline.configuration

if defined?(Rails)
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
