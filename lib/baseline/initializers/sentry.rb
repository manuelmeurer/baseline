# frozen_string_literal: true

require "sentry-rails"

if sentry_config = Rails.application.env_credentials.sentry
  Sentry.init do |config|
    config.breadcrumbs_logger      = %i[active_support_logger http_logger]
    config.dsn                     = sentry_config.dsn
    config.excluded_exceptions    -= [ActiveRecord::RecordNotFound.to_s]
    config.include_local_variables = true
    config.release                 = Rails.configuration.revision
    config.send_default_pii        = true
    config.app_dirs_pattern        = /(app|baseline|bin|config|lib|spec)/
  end
end
