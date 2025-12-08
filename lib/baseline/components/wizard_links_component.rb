# frozen_string_literal: true

module Baseline
  class WizardLinksComponent < ApplicationComponent
    def initialize(form:, step_label: nil)
      @form, @step_label = form, step_label
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
