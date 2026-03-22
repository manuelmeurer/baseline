# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Ignore < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       ->(record) { !record.ignored? },
            success_message: "ignored successfully.",
            error_message:   "already ignored."
          ) do |record|
            record.ignored!
            if record.tasks.undone.find_by(identifier: :handle)&.done!
              inform "Task to handle #{record.class.model_name.human} marked as done."
            end
            suppress record.class::ServiceNotFound do
              record._do_process_ignored(_async: true)
            end
          end
        end
      end
    end
  end
end
