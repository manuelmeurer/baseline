# frozen_string_literal: true

# Overridden to handle unpersisted has_one records (e.g. auto-built by `super || build_*`),
# which would otherwise crash on URL generation due to nil id.
class Avo::Fields::HasOneField::IndexComponent < Avo::Fields::IndexComponent
  def call
    index_field_wrapper(**field_wrapper_args) do
      if @field.value&.persisted?
        link_to @field.label, helpers.resource_path(record: @field.value, resource: @field.target_resource)
      else
        tag.span("&mdash;".html_safe)
      end
    end
  end
end
