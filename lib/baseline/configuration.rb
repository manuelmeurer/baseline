# frozen_string_literal: true

module Baseline
  class Configuration
    attr_accessor :wrap_exceptions, :root
    attr_reader :env

    def initialize
      @wrap_exceptions = true
      @root            = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
      @env             = (Rails.env.to_sym if defined?(Rails))

      super
    end

    def env=(value)
      @env = value.to_sym
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
