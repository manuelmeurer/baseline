# frozen_string_literal: true

module Baseline
  class FormActionsComponent < ApplicationComponent
    def initialize(
      form,
      style =           :save,
      horizontal:       false,
      submit_label:     nil,
      submit_icon:      nil,
      submit_data:      {},
      submit_color:     Current.default_button_color,
      submit_disabled:  false,
      submit_css_class: nil,
      button_size:      nil)

      @form, @style, @horizontal, @submit_data, @submit_label, @submit_icon, @submit_color, @submit_disabled, @submit_css_class, @button_size =
        form, style, horizontal, submit_data, submit_label, submit_icon, submit_color, submit_disabled, submit_css_class, button_size
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
        raise "Unexpected style: #{@style}"
      end
    end
  end
end
