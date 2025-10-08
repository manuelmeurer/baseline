# frozen_string_literal: true

module Baseline
  module Sections
    class RenderAsText < ApplicationService
      def call(section)
        if section.persisted?
          cache_key = [
            :section_text,
            section
          ]

          Rails.cache.fetch(cache_key, force: Rails.env.development?) do
            generate section
          end
        else
          generate section
        end
      end

      private

        def generate(section)
          [
            section.headline&.upcase,
            Converters::HTMLToText.call(section.content.to_s)
          ].compact_blank
            .join("\n\n")
            .html_safe
        end
    end
  end
end
