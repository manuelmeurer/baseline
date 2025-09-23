# frozen_string_literal: true

module Baseline
  module Converters
    class MarkdownToHTML < ApplicationService
      LINE_BREAK_REGEX = %r{<br(\s*/)?>}.freeze

      def call(text, sanitize: false, avoid_paragraphs: false)
        return "" if text.blank?

        require "kramdown"
        require "kramdown-parser-gfm"

        cache_key = [
          :markdown_to_html,
          ActiveSupport::Digest.hexdigest(text),
          sanitize,
          avoid_paragraphs
        ]

        Rails.cache.fetch cache_key do
          # If we ever want to process the text without adding any block level elements (<p> etc.),
          # use this approach: https://island94.org/2025/07/customize-rails-i18n-key-suffixes-like-md-for-markdown
          Kramdown::Document
            .new(text, input: "GFM")
            .to_html
            .if(avoid_paragraphs) { _1.gsub("<p>", "").gsub("</p>", "<br /><br />") }
            .gsub(/(#{LINE_BREAK_REGEX})\s+/, '\1') # Remove whitespace after <br> elements.
            .gsub(/(#{LINE_BREAK_REGEX})+\z/, "")   # Remove line breaks from end of string.
            .chomp
            .html_safe
            .if(sanitize) { Rails::Html::FullSanitizer.new.sanitize _1 }
        end
      end
    end
  end
end
