# frozen_string_literal: true

module MissionControl
  module Jobs
    class BaseController < ActionController::Base
      include Baseline::MissionControlJobsBaseControllable
      _baseline_finalize
    end
  end
end
