# frozen_string_literal: true

module ActiveJob::Querying
  extend ActiveSupport::Concern

  included do
    class_attribute :default_page_size, default: Baseline::Jobs.default_page_size
  end

  class_methods do
    def queues
      Baseline::Jobs.queues
    end

    def jobs
      Baseline::Jobs.jobs(default_page_size:)
    end
  end

  def queue
    Baseline::Jobs.queue_for(self)
  end

  module Root
    def queues
      Baseline::Jobs.queues
    end

    def jobs
      Baseline::Jobs.jobs(default_page_size: ActiveJob::Base.default_page_size)
    end
  end
end
