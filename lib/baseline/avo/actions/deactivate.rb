# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Deactivate < ::Avo::BaseAction
        def fields
          field :reason,
            as: :select,
            options: -> {
              record
                .deactivations
                .build
                .valid_reasons
                .index_by(&:titleize)
            }
          field :details, as: :textarea
        end

        def handle(query:, fields:, **)
          process(
            query,
            condition:       ->(record) { record.active? },
            success_message: "deactivated successfully.",
            error_message:   "already deactivated."
          ) do |record|
            record.deactivate!(**fields)
            suppress record.class::ServiceNotFound do
              record._do_process_deactivated(_async: true)
            end
          end
        end
      end
    end
  end
end
