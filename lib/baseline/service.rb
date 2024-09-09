# frozen_string_literal: true

require "active_record"
require "securerandom"
require "action_dispatch"
require "digest"

require "baseline/call_logger"
require "baseline/exception_wrapper"
require "baseline/uniqueness_checker"

module Baseline
  class Service < ActiveJob::Base
    prepend MemoWise

    delegate :link_to, :tag, :link_to_modal, :pluralize, to: :"ApplicationController.helpers"
    delegate :t, :l, to: :"I18n"

    queue_as :default

    class << self
      def inherited(subclass)
        subclass.const_set :Error, Class.new(StandardError)

        if defined?(Rails)
          subclass.public_send :include, Rails.application.routes.url_helpers
        end

        subclass.public_send :prepend, CallLogger, ExceptionWrapper, UniquenessChecker
      end

      delegate :call, to: :new

      alias_method :call_async, :perform_later

      def call_in(wait, *, **)
        set(wait: wait).perform_later(*, **)
      end

      def call_at(wait_until, *, **)
        set(wait_until: wait_until).perform_later(*, **)
      end

      %i(
        enqueued:   :ready
        scheduled:  :scheduled
        processing: :claimed
      ).each do |prefix, execution_type|
        define_method :"#{prefix}_jobs" do |*args|
          args = ActiveJob::Arguments.serialize(args)
          SolidQueue::Job
            .where(class_name: to_s)
            .joins(:"#{execution_type}_execution")
            .select {
              args.none? ||
                _1.arguments
                  .fetch("arguments")
                  .take(args.size) == args
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
      call *, **
    end

    def enqueued?(*)
      enqueued_jobs(*).any?
    end

    def processing?(*)
      processing_jobs(*).any?
    end

    def enqueued_or_processing?(*)
      enqueued?(*) || processing?(*)
    end

    def scheduled_at(*)
      scheduled_jobs(*).first&.then {
        _1.scheduled_execution.scheduled_at
      }
    end

    private

      def log(level, message, **kwargs)
        message = [
          message,
          kwargs.reverse_merge(service: self.class.to_s, id: @id)
                .map { [_1, _2].join(": ") }
                .join(", ")
                .then { "(#{_1})" }
        ].join(" ")

        Rails.logger.public_send level, message
      end

      def object_class
        self.class.to_s[/\A(?:Baseline::)?([^:]+)/, 1].singularize.constantize
      rescue
        raise "Could not determine service class from #{self.class}."
      end

      def track_last_run(cache_key_part = nil)
        now         = Time.current
        cache_key   = [self.class.to_s.underscore, cache_key_part, "last_run"].compact.join("_")
        last_run_at = Kredis.redis
                            .get(cache_key)
                            &.then { Time.zone.parse _1 }

        yield *[last_run_at].compact

        Kredis.redis.set cache_key, now.iso8601
      end

      def call_all_private_methods_without_args(raise_errors: true)
        private_methods(false).map { method _1 }
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
  end
end
