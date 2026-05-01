# frozen_string_literal: true

ActiveJob::ExecutionError = Baseline::Jobs::ExecutionError unless ActiveJob.const_defined?(:ExecutionError, false)
