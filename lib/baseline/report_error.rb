# frozen_string_literal: true

module Baseline
  class ReportError < Service
    def call(*error, **params)
      raise *error
    rescue => e
      Sentry.capture_exception e,
        contexts: { data: params }.compact_blank
    end
  end
end
