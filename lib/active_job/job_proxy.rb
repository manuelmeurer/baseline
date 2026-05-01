# frozen_string_literal: true

ActiveJob::JobProxy = Baseline::Jobs::JobProxy unless ActiveJob.const_defined?(:JobProxy, false)
