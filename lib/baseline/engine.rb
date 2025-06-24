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

      app.config.assets.paths << root.join("app", "javascript")
    end

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { load _1 }
    end
  end
end
