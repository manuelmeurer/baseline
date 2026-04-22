# frozen_string_literal: true

module Baseline
  class DrawerComponent < ApplicationComponent
    def before_render
      @stimco = helpers.stimco(:drawer, to_h: false)
    end
  end
end
