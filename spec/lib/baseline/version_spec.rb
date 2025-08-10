# frozen_string_literal: true

RSpec.describe Baseline::VERSION do
  it "has a version number" do
    expect(Baseline::VERSION).not_to be_nil
    expect(Baseline::VERSION).to be_a(String)
    expect(Baseline::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end
end