# frozen_string_literal: true

module Baseline
  module Sections
    class RenderAsText < ApplicationService
      def call(section)
        if section.persisted?
          cache_key = [
            :section_text,
            I18n.locale,
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
            section.headline.presence&.upcase,
            Converters::HTMLToText.call(section.content.to_s)
          ].compact
            .join("\n\n")
            .html_safe
        end
    end
  end
end
