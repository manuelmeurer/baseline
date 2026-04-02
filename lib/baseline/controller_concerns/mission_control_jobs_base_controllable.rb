# frozen_string_literal: true

module Baseline
  module MissionControlJobsBaseControllable
    extend ActiveSupport::Concern

    included do
      include Baseline::Authentication[:with_admin_user]

      before_action prepend: true do
        ::Current.namespace = :mission_control_jobs
      end
    end

    def mission_control_jobs_login_url = main_app.admin_login_url
  end
end
