module Baseline
  class Railtie < Rails::Railtie
    initializer "baseline.load_service" do
      require "report_error"
      require "has_timestamps"
    end
  end
end
