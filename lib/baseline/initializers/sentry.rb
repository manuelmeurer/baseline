# frozen_string_literal: true

require "sentry-rails"

Sentry.init do |config|
  config.breadcrumbs_logger      = %i[active_support_logger http_logger]
  config.dsn                     = Rails.application.env_credentials.sentry&.dsn || "dummy"
  config.excluded_exceptions    -= [ActiveRecord::RecordNotFound.to_s]
  config.include_local_variables = true
  config.release                 = Rails.configuration.revision
  config.send_default_pii        = true
end
