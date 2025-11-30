# frozen_string_literal: true

module Baseline
  module Wizardable
    extend ActiveSupport::Concern

    included do
      validates :form_step,
        absence:   { if: :finished? },
        inclusion: { in: :form_steps, allow_nil: true }
    end

    def form_steps = form_step_params.keys.map(&:to_s)

    def next_form_step
      if finished?
        raise "#{self.class.model_name.human} is already finished."
      end

      form_step ?
        form_steps[form_steps.index(form_step) + 1] :
        form_steps.first
    end

    def form_step_too_far_ahead?(step)
      return false unless next_step_index = next_form_step&.then { form_steps.index _1 }

      step_index =
        step == Wizardify::FINISH_STEP ?
          form_steps.size :
          form_steps.index(step)

      step_index > next_step_index
    end

    def reached_form_step?(step)
      return true if finished?

      # Return false if the current form step is blank or invalid.
      return false unless form_step.present? && form_step_index = form_steps.index(form_step)

      # If step is not included in form steps, return false.
      # This might happen because certain steps are not always included.
      return false unless step_index = form_steps.index(step.to_s)

      form_step_index >= step_index
    end
  end
end
