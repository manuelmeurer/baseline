# frozen_string_literal: true

module Baseline
  class LoadingComponent < ApplicationComponent
    def initialize(message: NOT_SET)
      @message = message
    end

    def before_render
      if @message == NOT_SET
        @message = t(:please_wait)
      end
    end
  end
end
