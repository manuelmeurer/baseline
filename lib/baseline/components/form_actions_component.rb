# frozen_string_literal: true

class FormActionsComponent < ApplicationComponent
  def initialize(form, horizontal: false, submit_label: nil, submit_data: {}, submit_button_color: :primary)
    @form, @horizontal, @submit_label, @submit_data, @submit_button_color =
      form, horizontal, submit_label, submit_data, submit_button_color
  end

  def before_render
    @submit_label ||= t(:save)
  end
end
