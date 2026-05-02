# frozen_string_literal: true

require "rails_helper"

RSpec.describe Baseline::HasStartAndEnd do
  it "works with ActiveModel models when type is given explicitly" do
    model_class = Class.new do
      include ActiveModel::Model
      include Baseline::HasStartAndEnd[:start_time, :end_time, type: :time]

      attr_accessor :start_time, :end_time
    end

    model = model_class.new(
      start_time: 1.hour.ago,
      end_time:   1.hour.from_now
    )

    expect(model).to be_current
  end
end
