# frozen_string_literal: true

require "avo"

::Avo.configure do |config|
  config.app_name                      = "Admin Dashboard"
  config.authorization_client          = :pundit
  config.click_row_to_view_record      = true
  config.currency                      = "EUR"
  config.explicit_authorization        = true
  config.license_key                   = Rails.application.env_credentials.avo.license_key!
  config.raise_error_on_missing_policy = true
  config.root_path                     = "cms"

  config.current_user_method do
    ::Current.admin_user
  end
end

::Avo::Engine.routes.default_url_options = {
  subdomain: "admin",
  host:      Rails.application.routes.default_url_options.fetch(:host)
}
