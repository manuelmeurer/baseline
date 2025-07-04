# frozen_string_literal: true

module Baseline
  class Engine < ::Rails::Engine
    isolate_namespace Baseline

    initializer "baseline.after_initialize" do |app|
      begin
        require "sitemap_generator"
      rescue LoadError
      else
        require "baseline/sitemap_generator"
      end

      I18n.load_path += Dir[root.join("config", "locales", "**", "*.yml")]

      app.config.assets.paths << root.join("app", "javascript")
    end

    initializer "baseline.assets.precompile" do |app|
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { load _1 }
    end
  end
end
