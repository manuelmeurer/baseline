# frozen_string_literal: true

module MissionControl
  module Jobs
    class BaseController < ActionController::Base
      include Baseline::MissionControlJobsBaseControllable
    end
  end
end
