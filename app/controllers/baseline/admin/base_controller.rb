# frozen_string_literal: true

module Baseline
  module Admin
    class BaseController < ::ApplicationController
      include Baseline::Authentication[:with_admin_user]

      layout "baseline/admin"

      helper_method :page_title

      before_action prepend: true do
        Current.tailwind  = true
        Current.namespace = :newadmin
      end

      private

        def page_title = "Admin"
    end
  end
end
