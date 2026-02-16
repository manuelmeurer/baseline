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
            condition:       -> { _1.active? },
            success_message: "deactivated successfully.",
            error_message:   "already deactivated."
          ) {
            _1.deactivate!(**fields)
          }
        end
      end
    end
  end
end
