# frozen_string_literal: true

module Web
  class ErrorsController < BaseController
    include Baseline::ErrorsControllable
  end
end
