# frozen_string_literal: true

module Baseline
  module Avo
    module ApplicationControllable
      extend ActiveSupport::Concern

      included do
        include ApplicationAvoShared,
                Baseline::Authentication[:with_admin_user]

        before_action prepend: true do
          Current.namespace = :avo
        end

        # This is duplicated for now from ApplicationControllerCore,
        # but we will not use Avo much longer, so that's ok.
        helper_method def prefix_namespace_unless_engine(name, **opts)
          [Current.namespace, name, opts].compact_blank
        end
      end

      def avo_login_url = main_app.admin_login_url
    end
  end
end
