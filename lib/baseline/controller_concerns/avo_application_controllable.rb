# frozen_string_literal: true

module Baseline
  module AvoApplicationControllable
    extend ActiveSupport::Concern

    included do
      include Baseline::Authentication["AdminUser"]

      before_action prepend: true do
        ::Current.namespace = :avo
      end
    end

    def avo_login_url = Rails.application.routes.url_helpers.admin_login_url
  end
end
