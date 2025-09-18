# frozen_string_literal: true

module Baseline
  module Sections
    class RenderAsMarkdown < ApplicationService
      def call(section, debug: false)
        [
          section.headline.presence&.then { "## #{_1}" },
          section.content.to_plain_text
        ].compact
          .join("\n\n")
          .html_safe
      end
    end
  end
end
