# frozen_string_literal: true

module Baseline
  module Admin
    class EssentialsController < BaseController
      include Baseline::EssentialsControllable
      _baseline_finalize
    end
  end
end
