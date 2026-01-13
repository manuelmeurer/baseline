# frozen_string_literal: true

module Baseline
  class WizardActionsComponent < ApplicationComponent
    def initialize(form:, step_label: nil, cancel_url: nil, show_current_step: true, button_color: "primary")
      @form, @step_label, @cancel_url, @show_current_step, @button_color =
        form, step_label, cancel_url, show_current_step, button_color
      @back_css_class = class_names(
        "btn", "btn-outline-dark", "order-4", "order-sm-0",
        "btn-lg" => !::Current.modal_request
      )
    end

    def before_render
      @step_label ||= t(:step).capitalize
    end

    private def submit_button(css_class: nil)
      css_class = class_names(
        "btn", "btn-#{@button_color}", *css_class,
        "btn-lg" => !::Current.modal_request
      )
      @form.button class: css_class do
        safe_join [
          t(helpers.last_step? ? :finish : :next).capitalize,
          component(:icon, :forward, style: :solid)
        ], " "
      end
    end
  end
end
