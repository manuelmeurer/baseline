# frozen_string_literal: true

module Baseline
  module Converters
    class HTMLToMarkdown < ApplicationService
      def call(html)
        return "" if html.blank?

        cache_key = [
          :html_to_md,
          ActiveSupport::Digest.hexdigest(html)
        ]

        Rails.cache.fetch cache_key do
          generate(html)
        end
      end

      private

        def generate(html)
          require "reverse_markdown"

          html = Nokogiri::HTML
            .fragment(html)
            .tap {
              _1.xpath(".//comment()")
                .remove
            }.to_html

          ReverseMarkdown
            .convert(html, github_flavored: true, tag_border: "")
            .chomp
        end
    end
  end
end
