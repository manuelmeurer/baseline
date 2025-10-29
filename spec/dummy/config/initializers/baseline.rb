# frozen_string_literal: true

require "baseline"

Baseline.configure do |config|
  config.wrap_exceptions = !Rails.env.development?
end
