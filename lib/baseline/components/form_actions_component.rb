# frozen_string_literal: true

module Baseline
  class FormActionsComponent < ApplicationComponent
    def initialize(
      form,
      style =       :save,
      horizontal:   false,
      submit_label: nil,
      submit_icon:  nil,
      submit_data:  {},
      button_color: Current.default_button_color,
      button_size:  nil)

      @form, @style, @horizontal, @submit_data, @submit_label, @submit_icon, @button_color, @button_size =
        form, style, horizontal, submit_data, submit_label, submit_icon, button_color, button_size
    end

    def before_render
      case @style
      when :save
        @submit_label ||= t(:save).capitalize
        @submit_icon  ||= "circle-check"
      when :submit
        @submit_label ||= t(:submit).capitalize
        @submit_icon  ||= "paper-plane"
      else
        raise "Unexpected style: #{style}"
      end
    end
  end
end
