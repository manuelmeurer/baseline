# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Reactivate < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       -> { !_1.active? },
            success_message: "reactivated successfully.",
            error_message:   "already active."
          ) {
            _1.reactivate!
          }
        end
      end
    end
  end
end
