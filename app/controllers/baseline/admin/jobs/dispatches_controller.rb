# frozen_string_literal: true

class Baseline::Admin::Jobs::DispatchesController < Baseline::Admin::Jobs::ApplicationController
  include Baseline::Jobs::JobScoped

  def create
    @job.dispatch
    redirect_to redirect_location, notice: "Dispatched job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      Baseline::Jobs.jobs
    end

    def redirect_location
      status = @job.status.presence_in(supported_job_statuses) || :blocked
      jobs_url(status)
    end
end
