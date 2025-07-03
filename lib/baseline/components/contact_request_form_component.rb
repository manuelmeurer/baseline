# frozen_string_literal: true

module Baseline
  class ContactRequestFormComponent < ApplicationComponent
    def initialize(kind, fields:, contact_request: ContactRequest.new(kind:), button_row_breakpoint: :sm, i18n_scope: nil, i18n_params: {})
      @kind, @fields, @contact_request, @button_row_breakpoint, @i18n_scope, @i18n_params =
        kind, fields, contact_request, button_row_breakpoint, i18n_scope, i18n_params
      @partial_data = { i18n_scope:, i18n_params: }.compact_blank
    end

    def before_render
      @turnstile_stimco = helpers.stimco(:turnstile, to_h: false)
      @data = data_merge(
        turbo_data(method: nil, confirm: false),
        @turnstile_stimco.to_h
      )
      @texts = [*@fields.flatten, :success, :error].index_with do |field|
        if field.is_a?(Hash)
          field = field.keys.first
        end
        @i18n_scope&.then { t(field, scope: _1, **@i18n_params, default: nil) } ||
          t(field, scope: %i[web contact_request_form])
      end
    end
  end
end
