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
  end
end
