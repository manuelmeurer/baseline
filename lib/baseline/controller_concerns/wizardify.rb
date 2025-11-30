# frozen_string_literal: true

module Baseline
  module Wizardify
    extend ActiveSupport::Concern

    PROTECTED_STEPS = [
      FINISH_STEP = "wizard_finish",
      FIRST_STEP  = "wizard_first",
      LAST_STEP   = "wizard_last"
    ]

    included do
      helper_method :wizard_path, :current_step?, :past_step?, :future_step?, :next_step?,  :previous_step?, :previous_step, :next_step

      helper_method def current_step  = @current_step
      helper_method def steps         = wizard_resource.form_steps
      helper_method def first_step?   = current_step == steps.first
      helper_method def last_step?    = current_step == steps.last
      helper_method def step_number   = steps.index(current_step) + 1
      helper_method def step_count    = steps.size
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

      before_action do
        @skip_to = nil
        @redirect_params = nil

        raise "No steps defined." unless steps

        if params[:id]
          @current_step  = setup_step_from(params[:id])
          @previous_step = previous_step(@current_step)
          @next_step     = next_step(@current_step)
        end
      end
    end

    def index = redirect_to_first_or_next_form_step

    def show
      if wizard_resource.form_step_too_far_ahead?(current_step)
        redirect_to_first_or_next_form_step
      else
        render_wizard
      end
    end

    def update
      wizard_resource.attributes = resource_params

      try :before_wizard_resource_update

      if wizard_resource.save
        try :after_wizard_resource_update
        render_wizard(wizard_resource)
      else
        render_turbo_response \
          error_message: wizard_resource.errors.full_messages.join(", ")
      end
    end

    def success; end

    private

      def resource_params
        params_for_step = wizard_resource
          .form_step_params
          .fetch(current_step.to_sym) {
            raise "Unexpected step: #{current_step}"
          }

        key = wizard_resource.class.to_s.underscore

        if params.key?(key)
          params.expect(key => params_for_step)
        else
          {}
        end.merge(form_step: current_step)
      end

      def action_i18n_scope(step = current_step)
        super() + [step].compact
      end

      def page_title_scope
        method(:action_i18n_scope).super_method.call
      end

      def previous_step(step = nil)
        return @previous_step if step.nil?

        index =  steps.index(step)
        step  =  steps.at(index - 1) if index.present? && index != 0
        step ||= steps.first
      end

      def next_step(step = nil)
        return @next_step if step.nil?

        index = steps.index(step)
        step  = steps.at(index + 1) if index.present?
        step  ||= FINISH_STEP
      end

      def current_step_index = steps.index(current_step)

      def current_and_given_step_exists?(step)
        current_step_index && steps.index(step)
      end

      def current_step?(step)
        current_and_given_step_exists?(step) && current_step == step
      end

      def past_step?(step)
        current_and_given_step_exists?(step) && current_step_index > steps.index(step)
      end

      def future_step?(step)
        current_and_given_step_exists?(step) && current_step_index < steps.index(step)
      end

      def previous_step?(step)
        current_and_given_step_exists?(step) && (current_step_index - 1)  == steps.index(step)
      end

      def next_step?(step)
        current_and_given_step_exists?(step) && (current_step_index + 1)  == steps.index(step)
      end

      # Overwrite to set a custom step value.
      def wizard_value(step) = step

      def render_wizard(resource = nil, options = {}, params = {})
        process_resource!(resource, options)

        if @skip_to
          url_params = params.reverse_merge(@redirect_params || {})
          redirect_to(wizard_path(@skip_to, url_params), options)
        else
          render_step(wizard_value(current_step), options, params)
        end
      end

      def process_resource!(resource, options = {})
        return unless resource

        did_save =
          options[:context] ?
            resource.save(context: options[:context]) :
            resource.save

        if did_save
          @skip_to ||= @next_step
        else
          @skip_to = nil
          options[:status] ||= :unprocessable_entity
        end
      end

      def render_step(step, options = {}, params = {})
        if step.nil? || step.to_s == FINISH_STEP
          redirect_to_finish_wizard options, params
        else
          render step, options
        end
      end

      def redirect_to_next(next_step, options = {}, params = {})
        if next_step.nil?
          redirect_to_finish_wizard(options, params)
        else
          redirect_to(wizard_path(next_step, params), options)
        end
      end

      def wizard_path(step = nil, options = {})
        options.merge(
          action: :show,
          id:     step || params[:id]
        ).then {
          url_for _1
        }
      end

      def redirect_to_finish_wizard(...)
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

        if ::Current.modal_request
          render_turbo_response \
            redirect:    finish_wizard_path,
            reload_main: true
        else
          html_redirect_to \
            finish_wizard_path
        end
      end

      def finish_wizard_path = { action: :success }

      def setup_step_from(step)
        return if steps.nil?

        step ||= steps.first

        case step.to_s
        when FIRST_STEP then redirect_to wizard_path(steps.first)
        when LAST_STEP  then redirect_to wizard_path(steps.last)
        end

        step.to_s.presence_in(steps + PROTECTED_STEPS) or
          raise ActionController::RoutingError, "Invalid step: #{step}"
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
