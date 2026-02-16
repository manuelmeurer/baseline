# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Activate < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       -> { !_1.active? },
            success_message: "activated successfully.",
            error_message:   "already active."
          ) {
            _1.activate!
          }
        end
      end
    end
  end
end
