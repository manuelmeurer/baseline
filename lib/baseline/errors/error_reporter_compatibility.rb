# frozen_string_literal: true

module Baseline
  module Errors
    module ErrorReporterCompatibility
      def add_middleware(middleware)
        unless middleware.respond_to?(:call)
          raise ArgumentError, "Error context middleware must respond to #call"
        end

        baseline_error_middlewares << middleware
      end

      def report(error, handled: true, severity: handled ? :warning : :error, context: {}, source: ActiveSupport::ErrorReporter::DEFAULT_SOURCE)
        context = ActiveSupport::ExecutionContext.to_h.merge(context || {})

        context = baseline_error_middlewares.inject(context) do |current_context, middleware|
          middleware.call(error, context: current_context, handled:, severity:, source:)
        end

        super(error, handled:, severity:, context:, source:)
      end

      private

        def baseline_error_middlewares
          @baseline_error_middlewares ||= []
        end
    end
  end
end
