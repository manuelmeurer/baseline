# frozen_string_literal: true

class Baseline::Admin::Jobs::ApplicationController < Baseline::Admin::BaseController
  helper Baseline::Admin::Jobs::ApplicationHelper

  include Baseline::Jobs::NotFoundRedirections
  include Baseline::Jobs::JobFilters

  helper_method :supported_job_statuses

  _baseline_finalize

  private

    def page_title = "Jobs"

    def supported_job_statuses
      Baseline::Jobs::STATUSES
    end
end
