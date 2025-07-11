# frozen_string_literal: true

module Baseline
  module ActsAsAvoResource
    extend ActiveSupport::Concern

    included do
      # https://github.com/avo-hq/avo/issues/3820
      abstract_resource!
    end

    class_methods do
      def _baseline_finalize
        # Accessing the model class here will raise a ActiveRecord::StatementInvalid
        # with cause PG::UndefinedTable if the table does not exist yet,
        # which is the case when running db:setup in CI.
        begin
          model_class
        rescue ActiveRecord::StatementInvalid => error
          return if error.cause.is_a?(PG::UndefinedTable)
          raise error
        end

        self.title = :to_s

        if model_class.respond_to?(:friendly)
          self.find_record_method = -> {
            id.is_a?(Array) ?
              query.where(slug: id) :
              query.friendly.find(id)
          }
        end
        if model_class.respond_to?(:search)
          self.search = {
            query: -> {
              query.search(params[:q])
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

    def timestamps
      field :created_at, as: :date_time, only_on: :display
      field :updated_at, as: :date_time, only_on: :show
    end
  end
end
