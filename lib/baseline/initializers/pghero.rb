# frozen_string_literal: true

Rails.application.config.to_prepare do
  require "pghero"

  PgHero::HomeController.class_eval do
    include Baseline::Authentication[:with_admin_user]

    before_action prepend: true do
      ::Current.namespace = :pghero
    end

    def pghero_login_url = Rails.application.routes.url_helpers.admin_login_url
  end
end
