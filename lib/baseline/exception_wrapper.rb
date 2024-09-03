# frozen_string_literal: true

module Baseline
  module ExceptionWrapper
    def call(*, **)
      super
    rescue => error
      if !Baseline.configuration.wrap_exceptions || error.class <= self.class::Error
        raise error
      else
        raise self.class::Error, error
      end
    end
  end
end
