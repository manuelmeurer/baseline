# frozen_string_literal: true

module Baseline
  class Railtie < Rails::Railtie
    initializer "baseline.load_classes" do
      require "baseline/has_timestamps"
    end
  end
end
