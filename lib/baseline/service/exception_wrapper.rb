module Baseline
  class Service
    module ExceptionWrapper
      def call(*args, **kwargs)
        super
      rescue StandardError => error
        if error.class <= self.class::Error
          raise error
        else
          raise self.class::Error, error
        end
      end
    end
  end
end
