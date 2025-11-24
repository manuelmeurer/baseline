# frozen_string_literal: true

module Admin
  class EssentialsController < BaseController
    include Baseline::EssentialsControllable
    _baseline_finalize
  end
end
