# frozen_string_literal: true

module Admin
  class SessionsController < BaseController
    include Baseline::AdminSessionsControllable
  end
end
