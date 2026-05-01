# frozen_string_literal: true

module Baseline
  module Storage
    class AttachmentFilter
      EXACT_MATCH_FILTERS = %i[
        record_type
        record_id
      ].freeze

      def initialize(scope, params)
        @scope, @params =
          scope, params.to_unsafe_h.symbolize_keys
      end

      def apply
        filter_exact_matches
        filter_name
        filter_content_type
        @scope
      end

      private

        def filter_exact_matches
          filters = @params.slice(*EXACT_MATCH_FILTERS).compact_blank
          @scope = @scope.where(filters) if filters.any?
        end

        def filter_name
          return unless @params[:name].present?

          name = ActiveRecord::Base.sanitize_sql_like(@params[:name])
          @scope = @scope.where("name LIKE ?", "%#{name}%")
        end

        def filter_content_type
          return unless @params[:content_type].present?

          @scope = @scope.joins(:blob).where(
            active_storage_blobs: { content_type: @params[:content_type] }
          )
        end
    end
  end
end
