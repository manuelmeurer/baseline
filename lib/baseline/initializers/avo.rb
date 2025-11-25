# frozen_string_literal: true

require "avo"

::Avo.configure do |config|
  config.app_name                      = "Admin Dashboard"
  config.click_row_to_view_record      = true
  config.currency                      = "EUR"
  config.license_key                   = Rails.application.env_credentials.avo.license_key!
  config.raise_error_on_missing_policy = true
  config.root_path                     = "cms"

  if @auth
    config.explicit_authorization = true
    config.authorization_client   = :pundit
    config.current_user_method do
      ::Current.admin_user
    end
  end
end

::Avo::Engine.routes.default_url_options = {
  subdomain: "admin",
  host:      Rails.application.routes.default_url_options.fetch(:host)
}

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

class ::Avo::Fields::BooleanField
  def as_toggle? = @args.key?(:as_toggle) ? !!@args[:as_toggle] : true
end
