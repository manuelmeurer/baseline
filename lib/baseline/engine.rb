# frozen_string_literal: true

module Baseline
  class Engine < ::Rails::Engine
    isolate_namespace Baseline

    config.autoload_paths << root.join("app", "components")

    initializer "baseline.after_initialize" do |app|
      begin
        require "sitemap_generator"
      rescue LoadError
      else
        require "baseline/sitemap_generator"
      end

      I18n.load_path += Dir[root.join("config", "locales", "**", "*.yml")]

      app.config.assets.paths << root.join("app", "javascript")

      components_path = root.join("lib", "baseline", "components")
      config.paths["app/views"] << components_path
      ActiveSupport.on_load(:action_controller) do
        append_view_path components_path
      end
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
