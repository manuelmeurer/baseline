# frozen_string_literal: true

module Baseline
  module ActsAsAvoResource
    extend ActiveSupport::Concern

    included do
      def self.inherited(subclass)
        subclass.title = :to_s

        if subclass.model_class.respond_to?(:friendly)
          subclass.find_record_method = -> {
            id.is_a?(Array) ?
              query.where(slug: id) :
              query.friendly.find(id)
          }
        end

        if subclass.model_class.respond_to?(:search)
          subclass.search = {
            query: -> {
              subclass
                .model_class
                .search(params[:q])
            }
          }
        end
      end
    end

    def truncate_on_index = -> { value.if(view == "index") { truncate _1, length: 50 } }
    def link              = -> { link_to nil, value, target: "_blank" if value.present? }

    def filters
      if model_class.respond_to?(:search)
        filter Baseline::Avo::Filters::Search
      end
    end

    def fields
      discover_columns
      discover_associations
    end
  end
end
