# frozen_string_literal: true

require "socket"

module Baseline
  module Errors
    class << self
      def enabled?
        Baseline.configuration.capture_exceptions && db_config.present?
      end

      def db_config
        return @db_config if defined?(@db_config)

        @db_config = ActiveRecord::Base.configurations.configs_for(
          env_name: Rails.env,
          name:     "errors"
        ).tap do |config|
          if config.blank?
            warn_missing_config_once
          end
        end
      end

      def db_config_present? = db_config.present?

      def ensure_schema!
        return unless enabled?

        Schema.define
      rescue => error
        Rails.logger.error(
          "[Baseline::Errors] schema setup failed: #{error.class}: #{error.message}"
        )
      end

      def install!
        return if @installed

        install_request_context_middleware
        install_error_context_middleware
        install_subscriber
        install_active_job_hook

        @installed = true
      end

      def normalize_error_message(message)
        message.to_s.first(10_000)
      end

      def normalize_backtrace(backtrace)
        Array(backtrace).first(200)
      end

      def normalize_context(context)
        normalize_value(context)
      end

      def table_name = :baseline_errors_issues

      def report_job_error(error, job_data:)
        return unless enabled?

        context = {
          job_class:       job_data["job_class"],
          job_id:          job_data["job_id"],
          queue_name:      job_data["queue_name"],
          executions:      job_data["executions"],
          provider_job_id: job_data["provider_job_id"],
          rails_env:       Rails.env,
          hostname:        Socket.gethostname,
          source:          "application.active_job"
        }.compact

        if job = ActiveSupport::ExecutionContext.to_h[:job]
          context.merge!(
            job_class:       job.class.name,
            job_id:          job.job_id,
            queue_name:      job.queue_name,
            executions:      job.executions,
            provider_job_id: job.provider_job_id
          )
        end

        Subscriber.new.report(
          error,
          handled:  false,
          severity: :error,
          context:,
          source:   context.fetch(:source)
        )
      end

      private

        def normalize_value(value)
          case value
          when NilClass, TrueClass, FalseClass, Integer, Float, String
            value
          when Symbol
            value.to_s
          when Time, Date, DateTime
            value.iso8601
          when Array
            value.map { normalize_value(_1) }
          when Hash
            value.to_h.transform_keys(&:to_s).transform_values { normalize_value(_1) }
          else
            if defined?(ActionController::Parameters) && value.is_a?(ActionController::Parameters)
              normalize_value(value.to_unsafe_h)
            elsif value.respond_to?(:to_global_id)
              value.to_global_id.to_s
            else
              value.to_s
            end
          end
        end

        def install_request_context_middleware
          Rails.application.middleware.insert_after(
            ActionDispatch::Executor,
            RequestContextMiddleware
          )
        rescue RuntimeError, ArgumentError
        end

        def install_error_context_middleware
          unless Rails.error.respond_to?(:add_middleware)
            Rails.error.singleton_class.prepend ErrorReporterCompatibility
          end

          Rails.error.add_middleware(ErrorContextMiddleware.new)
        end

        def install_subscriber
          Rails.error.subscribe(Subscriber.new)
        end

        def install_active_job_hook
          ActiveSupport.on_load(:active_job) do
            next if singleton_class < ActiveJobHook

            singleton_class.prepend ActiveJobHook
          end
        end

        def warn_missing_config_once
          return if @warned_missing_config

          Rails.logger.warn(
            "[Baseline::Errors] No 'errors' database configured for #{Rails.env}; capture disabled."
          )
          @warned_missing_config = true
        end
    end
  end
end
