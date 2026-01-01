# frozen_string_literal: true

require "securerandom"
require "digest"

require "baseline/call_logger"
require "baseline/exception_wrapper"
require "baseline/uniqueness_checker"

module Baseline
  class BaseService < defined?(ActiveJob) ? ActiveJob::Base : Object
    if defined?(MemoWise)
      prepend MemoWise
    end

    delegate :link_to, :tag, :link_to_modal, :pluralize, :component,
      to: "ApplicationController.helpers"
    delegate :t, :l,
      to: "I18n"

    if defined?(ActiveJob)
      queue_as :default
      queue_with_priority 5
      retry_on ActiveRecord::Deadlocked
      discard_on ActiveJob::DeserializationError
    end

    class << self
      def inherited(subclass)
        subclass.const_set :Error, Class.new(StandardError)

        if defined?(Rails)
          subclass.include Rails.application.routes.url_helpers
        end

        modules = [
          CallLogger,
          ExceptionWrapper,
          (UniquenessChecker if defined?(Rails))
        ].compact

        subclass.prepend(*modules)
      end

      delegate :call, to: :new

      if defined?(ActiveJob)
        def call_async(*, **)
          if Baseline.configuration.async_inline
            call(*, **)
          else
            perform_later(*, **)
          end
        end

        def call_in(wait, *, **)
          set(wait:).perform_later(*, **)
        end

        def call_at(wait_until, *, **)
          set(wait_until:).perform_later(*, **)
        end

        {
          enqueued:   :ready,
          scheduled:  :scheduled,
          processing: :claimed,
          nil => nil
        }.each do |prefix, execution_type|
          define_method [prefix, :jobs].compact.join("_") do |*_args|
            args = ActiveJob::Arguments.serialize(_args)
            SolidQueue::Job
              .where(class_name: to_s)
              .if(execution_type) { _1.joins(:"#{_2}_execution") }
              .if(args.any?) {
                _1.select do |job|
                  job.arguments
                    .fetch("arguments")
                    .take(args.size) == args
                end
              }
          end

          define_method "#{prefix}?" do |*args|
            public_send("#{prefix}_jobs", *args).any?
          end
        end

        def enqueued_or_processing_jobs(*)
          enqueued_jobs(*) + processing_jobs(*)
        end

        def enqueued_or_processing?(*)
          enqueued?(*) || processing?(*)
        end

        def scheduled_at(*)
          scheduled_jobs(*)
            .first
            &.then {
              _1.scheduled_execution
                .scheduled_at
            }
        end
      end
    end

    def initialize(*, **)
      super
      @id = SecureRandom.hex(6)
    end

    def call(*, **)
      raise NotImplementedError
    end

    def perform(*, **)
      call(*, **)
    end

    private

      def async?
        defined?(ActiveJob) && executions > 0
      end

      def log(level, message, **kwargs)
        message = kwargs
          .reverse_merge(service: self.class.to_s, id: @id)
          .map { [_1, _2].join(": ") }
          .join(", ")
          .then {
            [
              message,
              "(#{_1})"
            ].join(" ")
          }

        if defined?(Rails)
          Rails.logger.public_send level, message
        else
          puts "[#{level}] #{message}"
        end
      end

      def object_class
        self.class.to_s[/\A(?:Baseline::)?([^:]+)/, 1].singularize.constantize
      rescue
        raise "Could not determine service class from #{self.class}."
      end

      def track_last_run(cache_key_part = nil)
        now         = Time.current
        cache_key   = [self.class.to_s.underscore, cache_key_part, :last_run].compact
        last_run_at = Rails.cache.read(cache_key)&.then { Time.zone.parse _1 }

        yield *[last_run_at].compact

        Rails.cache.write cache_key, now.iso8601
      end

      def call_all_private_methods_without_args(raise_errors: true, except: nil)
        private_methods(false)
          .if(except) { _1 - Array(_2).map(&:to_s) }
          .map { method _1 }
          .select { _1.arity == 0 }
          .sort_by { _1.source_location.last }
          .each do |method|

          method.call
        rescue => error
          if raise_errors
            raise error
          else
            ReportError.call error
          end
        end
      end

      def translate_with_optional_scopes(key, optional_scopes, **params)
        optional_scopes
          .size
          .downto(0)
          .map { optional_scopes.take(_1) }
          .map {
            [
              *key,
              *_1
            ].compact
              .join(".")
          }.lazy
          .map {
            t(_1, **params, default: nil)
          }.detect(&:present?)
      end

      def run_command(command)
        require "open3"
        stdout, stderr, status = Open3.capture3(command)
        unless status.success?
          error_message = [
           "Error running #{command}.",
           ("STDOUT: #{stdout}" if stdout.present?),
           ("STDERR: #{stderr}" if stderr.present?)
          ].compact.join("\n")
          raise self.class::Error, error_message
        end
        stdout
      end
  end
end
