# frozen_string_literal: true

module Baseline
  module Jobs
    STATUSES = %i[ pending failed in_progress blocked scheduled finished ]

    mattr_accessor :backtrace_cleaner,
      :filter_arguments
    mattr_accessor :default_page_size,
      default: 1000
    mattr_accessor :internal_query_count_limit,
      default: 500_000
    mattr_accessor :delay_between_bulk_operation_batches,
      default: 0
    mattr_accessor :scheduled_job_delay_threshold,
      default: 1.minute
    mattr_accessor :logger,
      default: ActiveSupport::Logger.new(nil)

    self.filter_arguments = []

    def self.job_arguments_filter
      Baseline::Jobs::ArgumentsFilter.new(filter_arguments)
    end

    def self.queues
      Baseline::Jobs::Queues.new(fetch_queues)
    end

    def self.jobs(default_page_size: self.default_page_size)
      Baseline::Jobs::Relation.new(default_page_size:)
    end

    def self.queue_for(active_job)
      queues[active_job.queue_name]
    end

    def self.fetch_queues
      Baseline::Jobs::SolidQueue.queues.collect do |queue|
        Baseline::Jobs::Queue.new(queue[:name], size: queue[:size], active: queue[:active])
      end
    end
  end
end
