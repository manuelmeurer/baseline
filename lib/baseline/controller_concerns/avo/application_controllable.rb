# frozen_string_literal: true

module Baseline
  module Avo
    module ApplicationControllable
      extend ActiveSupport::Concern

      included do
        include ApplicationAvoShared,
                Baseline::Authentication[:with_admin_user]

        before_action prepend: true do
          ::Current.namespace = :avo
        end
      end

      def avo_login_url = Rails.application.routes.url_helpers.admin_login_url
    end
  end
end
