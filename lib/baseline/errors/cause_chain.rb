# frozen_string_literal: true

module Baseline
  module Errors
    module CauseChain
      class << self
        def walk(error)
          causes = []
          current = error.cause

          while current
            causes << {
              class_name: current.class.name,
              message:    Baseline::Errors.normalize_error_message(current.message),
              backtrace:  Baseline::Errors.normalize_backtrace(current.backtrace)
            }
            current = current.cause
          end

          causes
        end
      end
    end
  end
end
