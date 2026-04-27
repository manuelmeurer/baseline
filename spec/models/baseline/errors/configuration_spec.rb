# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::Errors do
  it "is disabled by default in test" do
    expect(Baseline.configuration.capture_exceptions).to be(false)
    expect(Baseline::Errors.enabled?).to be(false)
  end
end
