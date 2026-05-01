# frozen_string_literal: true

ActiveJob::Queues = Baseline::Jobs::Queues unless ActiveJob.const_defined?(:Queues, false)
