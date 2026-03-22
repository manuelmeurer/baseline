# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class Unpublish < ::Avo::BaseAction
        def handle(query:, **)
          process(
            query,
            condition:       -> { _1.published? },
            success_message: "unpublished successfully.",
            error_message:   "not published."
          ) do |record|
            record.unpublished!
          end
        end
      end
    end
  end
end
