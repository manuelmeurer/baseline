# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.base_controller_class = %w[
    ActionController::API
    ActionController::Base
  ]
  config.lograge.custom_options = ->(event) {
    event
      .payload
      .slice(:request_id, :remote_ip, :host)
      .merge \
        time:   event.time.to_fs(:iso8601),
        params: event.payload[:params]&.except("controller", "action", "subdomain")
  }
  config.lograge.ignore_custom = ->(event) {
    event.payload[:controller] == "Rails::HealthController"
  }
end
