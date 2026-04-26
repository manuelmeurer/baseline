# frozen_string_literal: true

module Admin
  class ErrorsController < BaseController
    include Baseline::ErrorPagesControllable
    _baseline_finalize
  end
end
