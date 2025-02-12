# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module Baseline
  class MarkdownToHTML < ApplicationService
    LINE_BREAK_REGEX = %r(<br(\s*/)?>).freeze

    def call(text, sanitize: false, avoid_paragraphs: false)
      return "" if text.blank?

      cache_key = [
        :markdown_to_html,
        ActiveSupport::Digest.hexdigest(text),
        sanitize,
        avoid_paragraphs
      ]

      Rails.cache.fetch cache_key do
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
