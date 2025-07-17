# frozen_string_literal: true

module Baseline
  class ContactRequestFormComponent < ApplicationComponent
    def initialize(kind, contact_request: ContactRequest.new, button_row_breakpoint: :sm, i18n_scope: nil, i18n_params: {})
      @kind, @contact_request, @button_row_breakpoint, @i18n_scope, @i18n_params =
        kind, contact_request, button_row_breakpoint, i18n_scope, i18n_params
      @contact_request.kind ||= @kind
    end

    def before_render
      @turnstile_stimco = helpers.stimco(:turnstile, to_h: false)
      @data = data_merge(
        turbo_data(method: nil, confirm: false),
        @turnstile_stimco.to_h
      )
      @texts = [*@contact_request.fields.flatten, :success, :error].index_with do |field|
        if field.is_a?(Hash)
          field = field.keys.first
        end
        @i18n_scope&.then { t(field, scope: _1, **@i18n_params, default: nil) } ||
          t(field, scope: %i[web contact_request_form])
      end
    end

    def render_field(form, field)
      render_field_tag = ->(_form) do
        field_type =
          field.in?(%i[message links]) ?
            :text_area :
            (field == :email ? :email : :text)

        options = {
          required: field.in?(%i[name email locations employees message links referral]),
          data:     (helpers.stimco(:autosize) if field_type == :text_area)
        }.compact

        component :form_field,
          _form,
          field_type,
          field,
          label_style: :floating,
          label:       @texts.fetch(field),
          **options
      end

      if ContactRequest.column_names.include?(field.to_s)
        render_field_tag.call(form)
      else
        form.fields_for :details do |details_form|
          render_field_tag.call(details_form)
        end
      end
    end
  end
end
