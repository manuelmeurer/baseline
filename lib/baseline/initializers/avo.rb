# frozen_string_literal: true

require "avo"

::Avo.configure do |config|
  config.app_name                 = "Admin Dashboard"
  config.click_row_to_view_record = true
  config.currency                 = "EUR"
  config.license_key              = Rails.application.env_credentials.avo.license_key!
  config.root_path                = "cms"

  config.branding = {
    logo:     "brand/avo_logo.png",
    logomark: "brand/avo_logomark.png",
    favicon:  "icons/favicon.ico"
  }

  if defined?(@auth) && @auth
    config.authorization_client          = Baseline::Avo::PunditClientWithFallback
    config.explicit_authorization        = true
    config.raise_error_on_missing_policy = false
    config.current_user_method do
      ::Current.admin_user
    end
  end
end

require "url_manager"

::Avo::Engine.routes.default_url_options = ::URLManager.url_options(:admin)

class ::Avo::BaseAction
  include Baseline::Avo::ActionHelpers

  module ErrorHandler
    def handle(...)
      super
    rescue => error
      if error.class <= self.class::Error
        raise error
      else
        raise self.class::Error, error
      end
    end
  end

  def self.inherited(subclass)
    subclass.const_set :Error, Class.new(StandardError)
    subclass.prepend ErrorHandler
  end
end

if defined?(Lexxy)
  ::Avo.asset_manager.add_stylesheet "lexxy"
end

# Prevent has_one fields from trying to load unpersisted records (e.g. auto-built
# by `super || build_*`), which would generate a URL without a related_id and hit
# the has_many index route, causing a NoMethodError on `scope`.
class ::Avo::Fields::HasOneField
  module PersistedValue
    def value(...)
      result = super
      result&.persisted? ? result : nil
    end
  end
  prepend PersistedValue
end

# Extend global search (Cmd+K) to include matching sidebar navigation items
# above the regular search results.
Rails.application.config.after_initialize do
  ::Avo::SearchController.prepend(Module.new do
    def index
      super

      q = params[:q].to_s.strip
      return if q.blank?

      root = ::Avo.configuration.root_path
      navigation_results = ::Avo
        .resource_manager
        .resources_for_navigation
        .select { _1.navigation_label.downcase.include?(q.downcase) }
        .sort_by(&:navigation_label)
        .map do |resource|
          {
            _id:    resource.route_key,
            _label: resource.navigation_label,
            _url:   "/#{root}/resources/#{resource.route_key}"
          }
        end

      if navigation_results.present?
        body = JSON
          .parse(response.body)
          .reverse_merge(
            _navigation: {
              header: "Pages (#{navigation_results.size})",
              help: "",
              results: navigation_results,
              count: navigation_results.size
            }
          )
        response.body = body.to_json
      end
    end
  end)
end

class ::Avo::Fields::BooleanField
  def as_toggle? = @args.key?(:as_toggle) ? !!@args[:as_toggle] : true
end

# Default to the Rails app timezone (config.time_zone) instead of the browser's
# timezone for all datetime and time fields.
class ::Avo::Fields::DateTimeField
  module AppTimezone
    def timezone
      super ||
        Rails.application.config.time_zone.presence or
          raise "Rails app timezone not set."
    end
  end
  prepend AppTimezone
end
