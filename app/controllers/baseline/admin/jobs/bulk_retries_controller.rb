# frozen_string_literal: true

class Baseline::Admin::Jobs::BulkRetriesController < Baseline::Admin::Jobs::ApplicationController
  include Baseline::Jobs::FailedJobsBulkOperations

  def create
    jobs_to_retry_count = bulk_limited_filtered_failed_jobs.count
    bulk_limited_filtered_failed_jobs.retry_all

    redirect_to jobs_url(:failed), notice: "Retried #{jobs_to_retry_count} jobs"
  end
end
