# frozen_string_literal: true

module Baseline
  class FormActionsComponent < ApplicationComponent
    def initialize(form, horizontal: false, submit_label: nil, submit_data: {}, button_color: Current.default_button_color)
      @form, @horizontal, @submit_label, @submit_data, @button_color =
        form, horizontal, submit_label, submit_data, button_color
    end

    def before_render
      @submit_label ||= t(:save)
    end
  end
end
