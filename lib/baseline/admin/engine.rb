# frozen_string_literal: true

module Baseline
  module Admin
    class Engine < ::Rails::Engine
      isolate_namespace Baseline::Admin

      config.autoload_paths << root.join("app", "controllers")
      paths["config/routes.rb"] = root.join("config", "baseline_admin_routes.rb").to_s
    end
  end
end
