# frozen_string_literal: true

module Baseline
  module Sections
    class RenderAsMarkdown < ApplicationService
      def call(section)
        if section.persisted?
          cache_key = [
            :section_md,
            section
          ]

          Rails.cache.fetch(cache_key) do
            generate section
          end
        else
          generate section
        end
      end

      private

        def generate(section)
          [
            section.headline.presence&.then { "## #{_1}" },
            Converters::HTMLToMarkdown.call(section.content.body.to_html)
          ].compact
            .join("\n\n")
            .chomp
        end
    end
  end
end
