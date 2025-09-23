# frozen_string_literal: true

module Baseline
  module Sections
    class InitializeFromMarkdown < ApplicationService
      def call(markdown)
        return [] if markdown.blank?

        parse_markdown(markdown.strip).map {
          Section.new(_1)
        }
      end

      private

        def parse_markdown(markdown)
          cache_key = [
            :markdown_sections,
            ActiveSupport::Digest.hexdigest(markdown)
          ]

          Rails.cache.fetch cache_key do
            Baseline::Converters::MarkdownToHTML
              .call(markdown, avoid_paragraphs: true)
              .then { Nokogiri::HTML.fragment _1 }
              .children
              .slice_before { _1.name == "h2" }
              .map do |elements|

              headline = if elements.first.name == "h2"
                # Use `gsub` with "[[:blank:]]" instead of `strip`, so that "&nbsp;" is removed as well.
                elements
                  .shift
                  .content
                  .gsub(/(\A[[:blank:]]+)|([[:blank:]]+\z)/, "")
              end

              # Remove leading and trailing <br> tags.
              content = elements
                .drop_while { _1.matches?("br") }
                .reverse
                .drop_while { _1.matches?("br") }
                .reverse
                .map(&:to_s)
                .compact_blank
                .join # Don't join with "\n" here, it will result in additional whitespace.
                .strip

              {
                headline:,
                content:
              }
            end
          end
        end
    end
  end
end
