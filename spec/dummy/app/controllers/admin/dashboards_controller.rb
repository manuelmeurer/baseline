# frozen_string_literal: true

module Admin
  class DashboardsController < BaseController
    def show
      render "admin/dashboard"
    end
  end
end
