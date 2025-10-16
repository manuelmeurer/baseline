# frozen_string_literal: true

module Baseline
  class CopyableTextFieldComponent < ApplicationComponent
    def initialize(text, button_color: Current.default_button_color, css_class: nil)
      @text, @button_color, @css_class =
        text, button_color, css_class
    end

    def call
      stimco = helpers.stimco(:copy_to_clipboard, to_h: false)

      tag.div class: ["input-group", @css_class], data: stimco.to_h do
        safe_join [
          text_field_tag(:text, @text, class: "form-control bg-white", data: stimco.target(:container), readonly: true),
          link_to("#", class: "btn btn-outline-#{@button_color}", data: stimco.action(:copy)) do
            safe_join [
              component(:icon, "copy"),
              t(:copy).capitalize
            ], " "
          end
        ]
      end
    end
  end
end
