# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Unignore < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       -> { _1.ignored? },
            success_message: "unignored successfully.",
            error_message:   "already unignored."
          ) {
            _1.unignored!
          }
        end
      end
    end
  end
end
