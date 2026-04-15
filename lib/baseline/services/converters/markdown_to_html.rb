# frozen_string_literal: true

module Baseline
  module Converters
    class MarkdownToHTML < ApplicationService
      LINE_BREAK_REGEX = %r{<br(\s*/)?>}.freeze

      def call(text, sanitize: false, avoid_paragraphs: false, add_class_to_first_paragraph: nil)
        return "" if text.blank?

        require "commonmarker"

        cache_key = [
          :markdown_to_html,
          ActiveSupport::Digest.hexdigest(text),
          sanitize,
          avoid_paragraphs,
          add_class_to_first_paragraph
        ]

        Rails.cache.fetch cache_key, force: Rails.env.development? do
          # If we ever want to process the text without adding any block level elements (<p> etc.),
          # use this approach: https://island94.org/2025/07/customize-rails-i18n-key-suffixes-like-md-for-markdown
          # unsafe:           allow raw HTML passthrough in markdown
          # hardbreaks:       convert soft line breaks (single newlines) to <br>
          # github_pre_lang:  use <code class="language-x"> instead of <pre lang="x">
          # header_ids:       generate id attributes for headings (empty string = no prefix)
          # block_directive:   enable generic block directive syntax (:::)
          # syntax_highlighter: nil disables built-in syntax highlighting
          Commonmarker.to_html(text, options: {
            render:    { unsafe: true, hardbreaks: true, github_pre_lang: false },
            extension: { header_ids: "", block_directive: true }
          }, plugins: { syntax_highlighter: nil })
            .if(add_class_to_first_paragraph) { _1.sub("<p>", %(<p class="#{_2}">)) }
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
