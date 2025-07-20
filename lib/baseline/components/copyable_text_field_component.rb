# frozen_string_literal: true

module Baseline
  class CopyableTextFieldComponent < ApplicationComponent
    def initialize(text, button_color: Current.default_button_color, css_class: nil)
      @text, @button_color, @css_class =
        text, button_color, css_class
    end

    def before_render
      @clipboard_stimco = helpers.stimco(:copy_to_clipboard, to_h: false)
    end
  end
end
