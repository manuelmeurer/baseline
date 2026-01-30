# frozen_string_literal: true

module Baseline
  module Avo
    module ApplicationControllable
      extend ActiveSupport::Concern

      included do
        include Baseline::Authentication[:with_admin_user]

        before_action prepend: true do
          ::Current.namespace = :avo
        end

        # Avo's default-value hydration reads via_relation_class, but the modal flow sends via_belongs_to_resource_class.
        # Normalize here so "new via belongs_to" preselects the parent consistently across resources.
        before_action do
          params[:via_relation_class] ||= params[:via_belongs_to_resource_class]
        end
      end

      def avo_login_url = Rails.application.routes.url_helpers.admin_login_url
    end
  end
end
