# frozen_string_literal: true

module Baseline
  module Sections
    class InitializeFromMarkdown < ApplicationService
      def call(locales_and_markdown)
        return [] if locales_and_markdown.blank?

        if locales_and_markdown.is_a?(String)
          locales_and_markdown = { I18n.locale => locales_and_markdown }
        end

        sections = []
        locales_and_markdown.each do |locale, markdown|
          next if markdown.blank?

          I18n.with_locale locale do
            parse_markdown(markdown.strip)
              .each_with_index do |attributes, index|
                if existing_section = sections[index]
                  existing_section.attributes = attributes
                else
                  sections << Section.new(attributes)
                end
              end
          end
        end
        sections
      end

      private

        def parse_markdown(markdown)
          cache_key = [
            :markdown_sections,
            ActiveSupport::Digest.hexdigest(markdown)
          ]

          Rails.cache.fetch cache_key do
            Baseline::MarkdownToHTML
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
