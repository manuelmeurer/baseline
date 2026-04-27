# frozen_string_literal: true

module Baseline
  module Admin
    class DashboardsController < BaseController
      def show
        render "baseline/admin/dashboard"
      end

      _baseline_finalize
    end
  end
end
