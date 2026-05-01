# frozen_string_literal: true

class Baseline::Admin::Jobs::BulkDiscardsController < Baseline::Admin::Jobs::ApplicationController
  include Baseline::Jobs::FailedJobsBulkOperations

  def create
    jobs_to_discard_count = jobs_to_discard.count
    jobs_to_discard.discard_all

    redirect_to jobs_url(:failed), notice: "Discarded #{jobs_to_discard_count} jobs"
  end

  private
    def jobs_to_discard
      if active_filters?
        bulk_limited_filtered_failed_jobs
      else
        Baseline::Jobs.jobs.failed
      end
    end
end
