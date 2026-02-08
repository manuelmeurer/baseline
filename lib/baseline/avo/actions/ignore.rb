# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Ignore < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       -> { !_1.ignored? },
            success_message: "ignored successfully.",
            error_message:   "already ignored."
          ) {
            _1.ignored!
            if _1.tasks.undone.find_by(identifier: :handle)&.done!
              inform "Task to handle #{_1.class.model_name.human} marked as done."
            end
          }
        end
      end
    end
  end
end
