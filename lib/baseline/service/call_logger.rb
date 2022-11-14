module Baseline
  class Service
    module CallLogger
      def self.prepended(mod)
        mod.extend ClassMethods
        mod.instance_eval do
          def inherited(subclass)
            subclass.extend ClassMethods
            subclass.disable_call_logging if self.call_logging_disabled
          end
        end
      end

      module ClassMethods
        @_call_logging_disabled = false

        def call_logging_disabled
          @_call_logging_disabled
        end

        def disable_call_logging
          @_call_logging_disabled = true
        end

        def enable_call_logging
          @_call_logging_disabled = false
        end
      end

      def call(*args, **kwargs)
        unless self.class.call_logging_disabled
          log :info, "START", args: args, kwargs: kwargs, caller: caller
          start = Time.now
        end
        begin
          result = super
        rescue => error
          log :error, exception_message(error)
          raise error
        ensure
          unless self.class.call_logging_disabled
            log :info, "END", duration: (Time.now - start).round(2)
          end
          result
        end
      end

      private

      def exception_message(e)
        message = "#{e.class}: #{e.message}"
        e.backtrace.each do |line|
          message << "\n  #{line}"
        end
        message << "\ncaused by: #{exception_message(e.cause)}" if e.respond_to?(:cause) && e.cause
        message
      end

      def caller
        caller_location = caller_locations(1, 10).detect do |location|
          location.path !~ /\A#{Regexp.escape File.expand_path("../..", __FILE__)}/
        end
        if caller_location.nil?
          nil
        else
          caller_path = caller_location.path
          caller_path = caller_path.sub(%r(\A#{Regexp.escape Rails.root.to_s}/), "") if defined?(Rails)
          [caller_path, caller_location.lineno].join(":")
        end
      end
    end
  end
end
