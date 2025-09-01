# frozen_string_literal: true

module Baseline
  module ActsAsAvoResource
    extend ActiveSupport::Concern

    class_methods do
      def _baseline_finalize
        return unless model_class.db_and_table_exist?

        if defined?(@_baseline_finalized)
          raise "Avo resource #{name} has already been finalized."
        end

        self.title = :to_s

        self.row_controls_config = {
          float: true
        }

        if model_class.respond_to?(:search)
          self.search = {
            query: -> {
              query.search(params[:q])
            }
          }
        end

        @_baseline_finalized = true
      end
    end

    def truncate_on_index = -> { value.if(view == "index") { truncate _1, length: 50 } }
    def link              = -> { link_to nil, value, target: "_blank" if value.present? }

    def polymorphic_types_with_resource(attribute)
      model_class
        .polymorphic_types(attribute)
        .select { ::Avo::Resources.const_defined?(_1, false) }
        .map(&:constantize)
    end

    def filters
      if model_class.respond_to?(:search)
        filter Baseline::Avo::Filters::Search
      end
    end

    def fields
      discover_columns
      discover_associations
    end

    def timestamps
      field :created_at, as: :date_time, only_on: :display
      field :updated_at, as: :date_time, only_on: :show
    end
  end
end
