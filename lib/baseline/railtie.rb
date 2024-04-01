module Baseline
  class Railtie < Rails::Railtie
    initializer "baseline.load_classes" do
      require "baseline/service"
      require "baseline/external_service"
      require "baseline/report_error"
      require "baseline/has_timestamps"
      require "baseline/if"
      require "baseline/deep_fetch"

      Rails.application.reloader.to_prepare do
        Current.missing_value = "_missing_value_"
      end
    end
  end
end
