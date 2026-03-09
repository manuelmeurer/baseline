# frozen_string_literal: true

module Baseline
  module Converters
    class TextToMarkdownBlockquote < ApplicationService
      def call(text)
        return "" if text.blank?

        cache_key = [
          :text_to_markdown_blockquote,
          ActiveSupport::Digest.hexdigest(Array(text).join("\n"))
        ].join(":")

        Rails.cache.fetch cache_key do
          text
            .unless(Array) {
              _1.gsub(/[ \t]*\r?\n[ \t]*/, "\n")
                .strip
                .gsub(/\n{2,}/, "\n\n")
                .split("\n")
            }.map { _1.empty? ? ">" : "> #{_1}" }
            .join("\n")
        end
      end
    end
  end
end
