# frozen_string_literal: true

module Baseline
  class Configuration
    attr_accessor :wrap_exceptions, :root

    def initialize
      @wrap_exceptions = true
      @root            = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)

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
