# frozen_string_literal: true

# Overridden to use `dash_if_blank: @field.value.nil?`,
# so that nil values are displayed as "-" instead of a blank badge.
class Avo::Fields::BadgeField::IndexComponent < Avo::Fields::IndexComponent
  def call
    index_field_wrapper(**field_wrapper_args, flush: true, dash_if_blank: @field.value.nil?) do
      render Avo::Fields::Common::BadgeViewerComponent.new(value: @field.value, options: @field.options)
    end
  end
end
