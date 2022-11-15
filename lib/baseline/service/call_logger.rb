module Baseline
  class Service
    module CallLogger
      def call(*args, **kwargs)
        log :info, "START", args: args, kwargs: kwargs, caller: caller

        start = Time.now

        begin
          result = super
        rescue => error
          log :error, exception_message(error)
          raise error
        ensure
          log :info, "END", duration: (Time.now - start).round(2).then { "#{_1}s" }
          result
        end
      end

      private

      def exception_message(error)
        [
          "#{error.class}: #{error.message}",
          *error.backtrace.map { "  #{_1}" },
          ("caused by: #{exception_message(error.cause)}" if error.respond_to?(:cause) && error.cause)
        ].compact
         .join("\n")
      end

      def caller
        caller_location = caller_locations(1, 10).detect do |location|
          location.path !~ /\A#{Regexp.escape File.expand_path("../..", __FILE__)}/
        end
        caller_location&.then do
          [
            _1.path.delete_prefix(Rails.root.to_s),
            _1.lineno
          ].join(":")
        end
      end
    end
  end
end
