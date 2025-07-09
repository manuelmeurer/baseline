# frozen_string_literal: true

module Baseline
  module UniquenessChecker
    KEY_PREFIX = %w[
      baseline
      uniqueness
    ].join(":")
      .freeze

    ON_ERROR = %i[
      fail
      ignore
      reschedule
      return
    ].freeze

    MAX_RETRIES = 10.freeze
    ONE_HOUR    = (60 * 60).freeze
    THIRTY_DAYS = (ONE_HOUR * 24 * 30).freeze

    def self.prepended(mod)
      mod.const_set :NotUniqueError, Class.new(mod::Error)
    end

    def check_uniqueness(*args, on_error: :fail)
      unless ON_ERROR.include?(on_error.to_sym)
        raise "on_error must be one of #{ON_ERROR.join(", ")}, but was #{on_error}"
      end

      return if @_ignore_uniqueness_check

      @_on_error = on_error

      if @_service_args.nil?
        raise "Service args not found."
      end

      @_uniqueness_args = args.empty? ?
        @_service_args :
        args
      new_uniqueness_key = uniqueness_key(@_uniqueness_args)
      if @_uniqueness_keys && @_uniqueness_keys.include?(new_uniqueness_key)
        raise "A uniqueness key with args #{@_uniqueness_args.inspect} already exists."
      end

      if @_similar_service_id = Rails.cache.read(new_uniqueness_key)
        return false if on_error.to_sym == :ignore
        @_retries_exhausted =
          on_error.to_sym == :reschedule &&
          error_count >= MAX_RETRIES
        raise_not_unique_error
      else
        @_uniqueness_keys ||= []
        @_uniqueness_keys << new_uniqueness_key
        Rails.cache.write new_uniqueness_key, @id, expires_in: ONE_HOUR
        true
      end
    end

    def call(*args, _ignore_uniqueness_check: false, **kwargs)
      @_ignore_uniqueness_check = _ignore_uniqueness_check
      @_service_args = args
      super(*args, **kwargs)
    rescue self.class::NotUniqueError => e
      case @_on_error.to_sym
      when :fail
        raise e
      when :reschedule
        if @_retries_exhausted
          raise e
        else
          increase_error_count
          reschedule
        end
      when :return
        return e
      else
        raise "Unexpected on_error: #{@_on_error}"
      end
    ensure
      unless Array(@_uniqueness_keys).empty?
        Rails.cache.delete @_uniqueness_keys
      end
      Rails.cache.delete error_count_key
    end

    private

      def raise_not_unique_error
        message = [
          "Service #{self.class} #{@id} with uniqueness args #{@_uniqueness_args} is not unique, a similar service is already running: #{@_similar_service_id}.",
          ("The service has been retried #{MAX_RETRIES} times." if @_retries_exhausted)
        ].compact
          .join(" ")

        raise self.class::NotUniqueError.new(message)
      end

      def convert_for_rescheduling(arg)
        case arg
        when Array
          arg.map do |array_arg|
            convert_for_rescheduling array_arg
          end
        when Integer, String, TrueClass, FalseClass, NilClass
          arg
        when object_class
          arg.id
        else
          raise "Don't know how to convert arg #{arg.inspect} for rescheduling."
        end
      end

      def reschedule
        # Convert service args for rescheduling first
        reschedule_args = @_service_args.map do |arg|
          convert_for_rescheduling arg
        end
        log :info, "Rescheduling", seconds: retry_delay
        self.class.call_in retry_delay, *reschedule_args
      end

      def error_count
        (Rails.cache.read(error_count_key) || 0).to_i
      end

      def increase_error_count
        Rails.cache.write \
          error_count_key,
          error_count + 1,
          expires_in: retry_delay + THIRTY_DAYS
      end

      def uniqueness_key(args)
        [
          KEY_PREFIX,
          self.class.to_s.gsub(":", "_"),
          (Digest::MD5.hexdigest(args.to_s) unless args.empty?)
        ].compact
          .join(":")
      end

      def error_count_key
        [
          KEY_PREFIX,
          "errors",
          self.class.to_s.gsub(":", "_")
        ].tap do |key|
          key << Digest::MD5.hexdigest(@_service_args.to_s) unless @_service_args.empty?
        end.join(":")
      end

      def retry_delay
        error_count ** 3 + 5
      end
  end
end
