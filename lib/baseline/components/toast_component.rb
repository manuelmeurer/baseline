# frozen_string_literal: true

module Baseline
  class ToastComponent < ApplicationComponent
    def before_render
      @stimco = helpers.stimco(:toast, to_h: false)
    end
  end
end
