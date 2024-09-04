# frozen_string_literal: true

module Baseline
  class Configuration
    attr_accessor :redis, :wrap_exceptions

    def initialize
      @wrap_exceptions = true
      super
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configuration=(config)
      @configuration = config
    end

    def configure
      yield configuration
    end
  end
end
