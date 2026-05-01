# frozen_string_literal: true

class Baseline::Admin::Jobs::DiscardsController < Baseline::Admin::Jobs::ApplicationController
  include Baseline::Jobs::JobScoped

  def create
    @job.discard
    redirect_to redirect_location, notice: "Discarded job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      Baseline::Jobs.jobs
    end

    def redirect_location
      status = @job.status.presence_in(supported_job_statuses) || :failed
      jobs_url(status, **jobs_filter_param)
    end
end
