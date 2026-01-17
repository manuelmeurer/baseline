# frozen_string_literal: true

module Baseline
  class Configuration
    attr_accessor :wrap_exceptions, :root, :no_paper_trail_classes, :custom_icon_classes, :async_inline, :i18n_namespace_fallbacks
    attr_reader :env

    def initialize
      @async_inline             = false
      @custom_icon_classes      = []
      @env                      = Rails.env.to_sym if defined?(Rails)
      @i18n_namespace_fallbacks = {}
      @no_paper_trail_classes   = []
      @root                     = defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
      @wrap_exceptions          = true

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
