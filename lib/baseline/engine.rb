# frozen_string_literal: true

module Baseline
  class Engine < ::Rails::Engine
    isolate_namespace Baseline

    initializer "baseline.after_initialize" do |app|
      # This validator must be loaded after the app's code is loaded,
      # because the class name depends on whether "URL" is registered as an acronym.
      require "baseline/url_format_validator"

      app.config.assets.paths << root.join("app", "javascript")
    end
  end
end
