# frozen_string_literal: true

module Baseline
  module Wizardify
    extend ActiveSupport::Concern

    included do
      include Wicked::Wizard

      # https://github.com/zombocom/wicked/issues/196
      rescue_from Wicked::Wizard::InvalidStepError do
        raise ActionController::RoutingError, "Invalid step"
      end

      helper_method :previous_step, :next_step
      helper_method def first_step?   = step == steps.first
      helper_method def last_step?    = step == steps.last
      helper_method def step_number   = wizard_steps.index(step) + 1
      helper_method def step_count    = wizard_steps.size
      helper_method def step_progress = (step_number.to_f * 100 / step_count).round

      before_action only: :success do
        unless wizard_resource.finished?
          redirect_to_first_or_next_form_step
        end
      end

      before_action except: :success do
        if wizard_resource.finished?
          if respond_to?(:already_finished, true)
            already_finished
          end

          redirect_to_finish_wizard
        end
      end

      before_action :setup_wizard
    end

    def index = redirect_to_first_or_next_form_step

    def show
      if wizard_resource.form_step_too_far_ahead?(step)
        redirect_to_first_or_next_form_step
      else
        render_wizard
      end
    end

    def success; end

    private

      def finish_wizard_path = { action: :success }

      def action_i18n_scope(_step = step)
        super() + [_step].compact
      end

      def redirect_to_finish_wizard(*)
        if wizard_resource.unfinished?
          wizard_resource.transaction do
            if respond_to?(:before_finish_wizard, true)
              before_finish_wizard
            end

            wizard_resource.form_step = nil
            wizard_resource.finished!

            if respond_to?(:after_finish_wizard, true)
              after_finish_wizard
            end
          end
        end

        if Current.modal_request
          render_turbo_response \
            redirect:    finish_wizard_path,
            reload_main: true
        else
          html_redirect_to \
            finish_wizard_path
        end
      end

      def redirect_to_first_or_next_form_step
        first_or_next_form_step =
          if wizard_resource.form_step
            if wizard_resource.form_step == steps.last
              # This should never happen, since after the last step is saved,
              # finished_at should be set to the current time and form_step to nil.
              # Maybe something went wrong in `before_finish_wizard` or `after_finish_wizard`.
              # Let's show the last step again.
              steps.last
            else
              wizard_resource.next_form_step
            end
          else
            steps.first
          end

        unless first_or_next_form_step
          raise "First or next form step is nil, this should never happen."
        end

        html_redirect_to \
          wizard_path(first_or_next_form_step)
      end
  end
end
