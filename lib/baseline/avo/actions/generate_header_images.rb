# frozen_string_literal: true

module Baseline
  module Avo
    module Actions
      class GenerateHeaderImages < ::Avo::BaseAction
        def handle(query:, **)
          query.each(&:_do_generate_header_images)
          succeed "Header images generated."
        end
      end
    end
  end
end
