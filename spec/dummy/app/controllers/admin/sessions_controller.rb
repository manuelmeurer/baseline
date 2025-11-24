# frozen_string_literal: true

module Admin
  class SessionsController < BaseController
    include Baseline::AdminSessionsControllable
    _baseline_finalize
  end
end
