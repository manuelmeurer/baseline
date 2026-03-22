# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Publish < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       ->(record) { record.unpublished? },
            success_message: "published successfully.",
            error_message:   "already published."
          ) do |record|
            record.published!
            suppress record.class::ServiceNotFound do
              record._do_process_published(_async: true)
            end
          end
        end
      end
    end
  end
end
