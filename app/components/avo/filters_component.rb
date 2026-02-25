# frozen_string_literal: true

# Override Avo's FiltersComponent to render filters inline instead of in a dropdown.
# We need to re-implement the full class because ViewComponent requires the class
# file to exist alongside the template for proper template resolution.

# Verify original implementation hasn't changed from version 3.28.0, when this override was created.
Baseline::VerifyGemFileSource.call(
  "avo",
  "app/components/avo/filters_component.rb" => "2e3fdf31b20da83cddc193dba658f3b55caf7df69094a0768b7dccc647ebe924",
  "app/components/avo/filters_component.html.erb" => "b024280c5bf1ff1dc27a5111478cd87c48bd66cd0086c16bfc7efd0a232b4eda"
)

class Avo::FiltersComponent < Avo::BaseComponent
  include Avo::ApplicationHelper

  prop :filters, default: [].freeze
  prop :resource
  prop :applied_filters, default: {}.freeze
  prop :parent_record

  def render? = @filters.present?

  def reset_path
    if @parent_record.present?
      helpers.related_resources_path \
        @parent_record,
        @parent_record,
        encoded_filters:   nil,
        reset_filter:      true,
        keep_query_params: true
    else
      helpers.resources_path \
        resource:          @resource,
        encoded_filters:   nil,
        reset_filter:      true,
        keep_query_params: true
    end
  end
end
