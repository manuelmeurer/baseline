# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class GenerateHeaderImages < ::Avo::BaseAction
        def handle(query:, **)
          query.each do |record|
            Baseline::GenerateHeaderImages.call(record)
          end
          succeed "Header images generated."
        end
      end
    end
  end
end
