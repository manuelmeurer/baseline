# frozen_string_literal: true

ActiveJob::Queue = Baseline::Jobs::Queue unless ActiveJob.const_defined?(:Queue, false)
