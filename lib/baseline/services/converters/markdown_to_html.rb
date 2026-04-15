# frozen_string_literal: true

module Baseline
  module Converters
    class MarkdownToHTML < ApplicationService
      LINE_BREAK_REGEX = %r{<br(\s*/)?>}.freeze

      def call(text, sanitize: false, avoid_paragraphs: false, add_class_to_first_paragraph: nil)
        return "" if text.blank?

        require "commonmarker"
        require "nokogiri"

        cache_key = [
          :markdown_to_html,
          ActiveSupport::Digest.hexdigest(text),
          sanitize,
          avoid_paragraphs,
          add_class_to_first_paragraph
        ]

        Rails.cache.fetch cache_key, force: Rails.env.development? do
          # Options used:
          # unsafe:             allow raw HTML passthrough in markdown
          # hardbreaks:         convert soft line breaks (single newlines) to <br>
          # github_pre_lang:    use <code class="language-x"> instead of <pre lang="x">
          # header_ids:         generate id attributes for headings (empty string = no prefix)
          # block_directive:    enable generic block directive syntax (:::)
          # syntax_highlighter: nil disables built-in syntax highlighting
          Commonmarker.to_html(text, options: {
            render:    { unsafe: true, hardbreaks: true, github_pre_lang: false },
            extension: { header_ids: "", block_directive: true }
          }, plugins: { syntax_highlighter: nil })
            .then { add_external_link_attributes _1 }
            .if(add_class_to_first_paragraph) { _1.sub("<p>", %(<p class="#{_2}">)) }
            .if(avoid_paragraphs) { _1.gsub("<p>", "").gsub("</p>", "<br /><br />") }
            .gsub(/(#{LINE_BREAK_REGEX})\s+/, '\1') # Remove whitespace after <br> elements.
            .gsub(/(#{LINE_BREAK_REGEX})+\z/, "")   # Remove line breaks from end of string.
            .chomp
            .html_safe
            .if(sanitize) { Rails::Html::FullSanitizer.new.sanitize _1 }
        end
      end

      private

        def add_external_link_attributes(html)
          fragment = Nokogiri::HTML5.fragment(html)
          external_links = fragment.css("a").select {
            _1[:href].to_s.match?(URLFormatValidator.regex) &&
              !_1[:href].match?(URLManager.internal_host_regex)
          }
          return html if external_links.empty?

          external_links.each do |link|
            ApplicationController.helpers.external_link_attributes.each do |key, value|
              link[key.to_s] = value
            end
          end
          fragment.to_html
        end
    end
  end
end
