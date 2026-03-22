# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Unpublish < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       ->(record) { record.published? },
            success_message: "unpublished successfully.",
            error_message:   "not published."
          ) do |record|
            record.unpublished!
            suppress record.class::ServiceNotFound do
              record._do_process_unpublished(_async: true)
            end
          end
        end
      end
    end
  end
end
