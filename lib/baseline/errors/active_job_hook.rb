# frozen_string_literal: true

module Baseline
  module Errors
    module ActiveJobHook
      def execute(job_data)
        super
      rescue Exception => error
        Baseline::Errors.report_job_error(error, job_data:)
        raise
      end
    end
  end
end
