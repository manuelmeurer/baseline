# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Reactivate < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       ->(record) { !record.active? },
            success_message: "reactivated successfully.",
            error_message:   "already active."
          ) do |record|
            record.reactivate!
            suppress record.class::ServiceNotFound do
              record._do_process_reactivated(_async: true)
            end
          end
        end
      end
    end
  end
end
