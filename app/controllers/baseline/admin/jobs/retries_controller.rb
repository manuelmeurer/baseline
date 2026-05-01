# frozen_string_literal: true

class Baseline::Admin::Jobs::RetriesController < Baseline::Admin::Jobs::ApplicationController
  include Baseline::Jobs::JobScoped

  def create
    @job.retry
    redirect_to \
      jobs_url(:failed, **jobs_filter_param),
      notice: "Retried job with id #{@job.job_id}"
  end

  private
    def jobs_relation
      Baseline::Jobs.jobs.failed
    end
end
