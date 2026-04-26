# frozen_string_literal: true

module Web
  class ErrorsController < BaseController
    include Baseline::ErrorPagesControllable
    _baseline_finalize
  end
end
