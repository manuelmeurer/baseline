module Baseline
  class Railtie < Rails::Railtie
    initializer "baseline.load_classes" do
      require "baseline/service"
      require "baseline/external_service"
      require "baseline/report_error"
      require "baseline/has_timestamps"
      require "baseline/if_unless"
      require "baseline/deep_fetch"
    end

    initializer "baseline.add_env_credentials" do
      Rails::Application.class_eval do
        def env_credentials(env = Rails.env)
          @env_credentials ||= {}
          @env_credentials[env] ||= begin
            creds = credentials.dup
            env_creds = creds.delete(:"__#{env}")
            creds.delete_if { _1.start_with?("__") }
            creds.deep_merge(env_creds || {})
          end
        end
      end
    end
  end
end
