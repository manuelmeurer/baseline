# frozen_string_literal: true

module Baseline
  module Avo
    module ResourcesControllable
      extend ActiveSupport::Concern

      included do
        # Avo's default-value hydration reads via_relation_class, but the modal flow sends via_belongs_to_resource_class.
        # Normalize here so "new via belongs_to" preselects the parent consistently across resources.
        before_action do
          params[:via_relation_class] ||= params[:via_belongs_to_resource_class]
        end

        # Convert ?search=foo into encoded_filters for the Search filter.
        before_action only: :index, if: -> { params[:search].present? } do
          search_value = params.delete(:search)
          resource_class = self
            .class
            .name
            .delete_prefix("Avo::")
            .delete_suffix("Controller")
            .singularize
            .then { "Avo::Resources::#{_1}" }
            .constantize

          unless resource_class.model_class.respond_to?(:search)
            ReportError.call "Resource #{resource_class} was called with a search param, but it has no search filter configured."
            redirect_to url_for(params.permit!)
            next
          end

          encoded = ::Avo::Filters::BaseFilter.encode_filters(
            Filters::Search.to_s => search_value
          )
          redirect_to url_for(params.permit!.merge(encoded_filters: encoded))
        end
      end
    end
  end
end
