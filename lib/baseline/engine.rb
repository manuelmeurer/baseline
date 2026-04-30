# frozen_string_literal: true

module Baseline
  class Engine < ::Rails::Engine
    isolate_namespace Baseline

    config.autoload_paths << root.join("app", "components")

    # hotwire-spark assumes all controllers have view helpers, which is not
    # the case for ActionController::API controllers. Guard accordingly.
    initializer "baseline.hotwire_spark_api_fix" do
      if defined?(Hotwire::Spark::Middleware)
        Hotwire::Spark::Middleware.prepend(Module.new do
          private def interceptable_request?
            super && @request.controller_instance.respond_to?(:helpers)
          end
        end)
      end
    end

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

      ActionController::Renderers.add :ics do |object, _|
        ical = object.try(:to_ical) || object
        send_data ical, type: Mime::Type.new("text/calendar")
      end
    end

    initializer "baseline.assets.precompile" do |app|
      app.config.assets.paths << root.join("app", "assets", "stylesheets")
    end

    initializer "baseline.errors.install", after: :load_config_initializers do
      Baseline::Errors.install!
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { load _1 }
    end
  end
end
