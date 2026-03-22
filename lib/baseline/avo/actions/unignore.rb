# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Unignore < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       ->(record) { record.ignored? },
            success_message: "unignored successfully.",
            error_message:   "already unignored."
          ) do |record|
            record.unignored!
            suppress record.class::ServiceNotFound do
              record._do_process_unignored(_async: true)
            end
          end
        end
      end
    end
  end
end
