# frozen_string_literal: true

require "sentry-rails"

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.dsn                = Rails.application.env_credentials.sentry&.dsn || "dummy"
  config.enable_logs        = true
  config.enabled_patches << :logger
  config.excluded_exceptions -= ["ActiveRecord::RecordNotFound"]
  config.include_local_variables = true
  config.rails.structured_logging.subscribers = {
    # active_record:     Sentry::Rails::LogSubscribers::ActiveRecordSubscriber,
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    active_job:        Sentry::Rails::LogSubscribers::ActiveJobSubscriber,
    action_mailer:     Sentry::Rails::LogSubscribers::ActionMailerSubscriber
  }
  config.release                 = Rails.configuration.revision
  config.send_default_pii        = true
end
