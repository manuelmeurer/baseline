# frozen_string_literal: true

module Baseline
  class WizardLinksComponent < ApplicationComponent
    def initialize(form:, step_label: nil, cancel_url: nil)
      @form, @step_label, @cancel_url =
        form, step_label, cancel_url
      @back_css_class = "btn btn-lg btn-outline-dark order-4 order-sm-0"
    end

    def before_render
      @step_label ||= t(:step).capitalize
    end

    private def submit_button(css_class: nil)
      @form.button class: ["btn", "btn-lg", "btn-primary", *css_class] do
        safe_join [
          t(helpers.last_step? ? :finish : :next).capitalize,
          component(:icon, :forward, style: :solid)
        ], " "
      end
    end
  end
end
