# frozen_string_literal: true

module Baseline
  NOT_SET = Object.new.freeze

  # Controller concerns
  autoload :APITodoistControllable, "baseline/controller_concerns/api_todoist_controllable"
  autoload :APIControllerCore,      "baseline/controller_concerns/api_controller_core"
  autoload :Authentication,         "baseline/controller_concerns/authentication"
  autoload :ControllerCore,         "baseline/controller_concerns/controller_core"
  autoload :I18nScopes,             "baseline/controller_concerns/i18n_scopes"
  autoload :NamespaceLayout,        "baseline/controller_concerns/namespace_layout"
  autoload :PageTitle,              "baseline/controller_concerns/page_title"
  autoload :RobotsSitemapManifest,  "baseline/controller_concerns/robots_sitemap_manifest"
  autoload :SetLocale,              "baseline/controller_concerns/set_locale"

  # Model concerns
  autoload :ActsAsInvoicingDetails, "baseline/model_concerns/acts_as_invoicing_details"
  autoload :ActsAsCreditNote,       "baseline/model_concerns/acts_as_credit_note"
  autoload :ActsAsMessage,          "baseline/model_concerns/acts_as_message"
  autoload :ActsAsNotification,     "baseline/model_concerns/acts_as_notification"
  autoload :ActsAsPDFFile,          "baseline/model_concerns/acts_as_pdf_file"
  autoload :ActsAsTask,             "baseline/model_concerns/acts_as_task"
  autoload :ActsAsTodoistEvent,     "baseline/model_concerns/acts_as_todoist_event"
  autoload :HasChargeVAT,           "baseline/model_concerns/has_charge_vat"
  autoload :HasCountry,             "baseline/model_concerns/has_country"
  autoload :HasFirstAndLastName,    "baseline/model_concerns/has_first_and_last_name"
  autoload :HasFullName,            "baseline/model_concerns/has_full_name"
  autoload :HasGender,              "baseline/model_concerns/has_gender"
  autoload :HasLocale,              "baseline/model_concerns/has_locale"
  autoload :HasMessageable,         "baseline/model_concerns/has_messageable"
  autoload :HasPDFFiles,            "baseline/model_concerns/has_pdf_files"
  autoload :HasTimestamps,          "baseline/model_concerns/has_timestamps"
  autoload :ModelCore,              "baseline/model_concerns/model_core"
  autoload :SaveSlugIdentifier,     "baseline/model_concerns/save_slug_identifier"
  autoload :TouchAsync,             "baseline/model_concerns/touch_async"

  # Services
  autoload :BaseService,            "baseline/services/base_service"
  autoload :DownloadFile,           "baseline/services/download_file"
  autoload :ExternalService,        "baseline/services/external_service"
  autoload :MarkdownToHTML,         "baseline/services/markdown_to_html"
  autoload :ReportError,            "baseline/services/report_error"
  autoload :SaveToTempfile,         "baseline/services/save_to_tempfile"
  autoload :Toucher,                "baseline/services/toucher"
  autoload :UpdateSchemaMigrations, "baseline/services/update_schema_migrations"

  module Avo
    module Filters
      autoload :Search,             "baseline/avo/filters/search"
    end
  end

  module External
    autoload :Lexoffice,            "baseline/services/external/lexoffice"
    autoload :Todoist,              "baseline/services/external/todoist"
    autoload :SlackSimple,          "baseline/services/external/slack_simple"

    module Google
      module Oauth
        autoload :Authorizer,       "baseline/services/external/google/oauth/authorizer"
        autoload :Helpers,          "baseline/services/external/google/oauth/helpers"
        autoload :Service,          "baseline/services/external/google/oauth/service"
      end
    end
  end

  module GoogleDrive
    autoload :Helpers,              "baseline/services/google_drive/helpers"
    autoload :SyncToLexoffice,      "baseline/services/google_drive/sync_to_lexoffice"
  end

  module InvoicingDetails
    autoload :UpsertLexoffice,      "baseline/services/invoicing_details/upsert_lexoffice"
  end

  module Lexoffice
    autoload :Helpers,              "baseline/services/lexoffice/helpers"
    autoload :DownloadPDF,          "baseline/services/lexoffice/download_pdf"
  end

  module Messages
    autoload :GeneratePartsFromI18n, "baseline/services/messages/generate_parts_from_i18n"
  end

  module Notifications
    autoload :Create,               "baseline/services/notifications/create"
  end

  module Recurring
    autoload :Base,                 "baseline/services/recurring/base"
  end

  module Sitemaps
    autoload :Fetch,                "baseline/services/sitemaps/fetch"
    autoload :GenerateAll,          "baseline/services/sitemaps/generate_all"
    autoload :Helpers,              "baseline/services/sitemaps/helpers"
  end

  module Tasks
    autoload :Create,               "baseline/services/tasks/create"

    module Todoist
      autoload :CreateAll,          "baseline/services/tasks/todoist/create_all"
      autoload :DeleteOld,          "baseline/services/tasks/todoist/delete_old"
      autoload :Update,             "baseline/services/tasks/todoist/update"
    end
  end

  module TodoistEvents
    autoload :Process,              "baseline/services/todoist_events/process"
  end

  # Components
  autoload :FormActionsComponent,   "baseline/components/form_actions_component"
  autoload :FormFieldComponent,     "baseline/components/form_field_component"
  autoload :ItemListComponent,      "baseline/components/item_list_component"

  autoload :ActsAsAvoResource,      "baseline/acts_as_avo_resource"
  autoload :ApplicationCore,        "baseline/application_core"
  autoload :ApplicationPolicy,      "baseline/application_policy"
  autoload :Current,                "baseline/current"
  autoload :Helper,                 "baseline/helper"
  autoload :MailerCore,             "baseline/mailer_core"
  autoload :RedisURL,               "baseline/redis_url"
  autoload :StimulusController,     "baseline/stimulus_controller"
  autoload :URLFormatValidator,     "baseline/url_format_validator"
  autoload :ZstdCompressor,         "baseline/zstd_compressor"

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
  end
end
