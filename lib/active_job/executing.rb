# frozen_string_literal: true

# TODO: These (or a version of them) should be moved to +ActiveJob::Core+
# and related concerns when upstreamed.
module ActiveJob::Executing
  extend ActiveSupport::Concern

  included do
    attr_accessor :raw_data, :filtered_raw_data, :position, :finished_at,
      :blocked_by, :blocked_until, :worker_id, :started_at, :status
    attr_reader :serialized_arguments
  end

  def retry
    Baseline::Jobs.jobs.failed.retry_job(self)
  end

  def discard
    jobs_relation_for_discarding.discard_job(self)
  end

  def dispatch
    Baseline::Jobs.jobs.dispatch_job(self)
  end

  private
    def jobs_relation_for_discarding
      case status
      when :failed  then Baseline::Jobs.jobs.failed
      when :pending then Baseline::Jobs.jobs.pending.where(queue_name: queue_name)
      else
        Baseline::Jobs.jobs
      end
    end
end
