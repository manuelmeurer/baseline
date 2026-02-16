# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Deactivate < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       -> { _1.active? },
            success_message: "deactivated successfully.",
            error_message:   "already deactivated."
          ) {
            _1.deactivate!
          }
        end
      end
    end
  end
end
