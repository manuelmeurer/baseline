# frozen_string_literal: true

module Baseline
  class CopyableTextFieldComponent < ApplicationComponent
    def initialize(text, button_color_class: :primary, css_class: nil)
      @text, @button_color_class, @css_class =
        text, button_color_class, css_class
    end

    def before_render
      @clipboard_stimco = helpers.stimco(:copy_to_clipboard, to_h: false)
    end
  end
end
