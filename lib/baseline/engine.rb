# frozen_string_literal: true

module Baseline
  class Engine < ::Rails::Engine
    isolate_namespace Baseline

    initializer "baseline.after_initialize" do |app|
      require "baseline/sitemap_generator"

      app.config.assets.paths << root.join("app", "javascript")
    end
  end
end
