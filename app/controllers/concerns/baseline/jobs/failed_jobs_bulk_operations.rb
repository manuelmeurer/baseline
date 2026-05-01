# frozen_string_literal: true

module Baseline::Jobs::FailedJobsBulkOperations
  extend ActiveSupport::Concern

  MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS = 3000

  included do
    include Baseline::Jobs::JobFilters
  end

  private
    # Keep filtered bulk operations bounded so expensive Solid Queue queries
    # cannot lock or scan an unexpectedly large set.
    def bulk_limited_filtered_failed_jobs
      Baseline::Jobs.jobs.failed.where(**@job_filters).limit(MAX_NUMBER_OF_JOBS_FOR_BULK_OPERATIONS)
    end
end
