# frozen_string_literal: true

module Baseline
  module Converters
    class TextToMarkdownBlockquote < ApplicationService
      def call(text)
        return "" if text.blank?

        text
          .unless(Array) { _1.split(/\r?\n/) }
          .map { "> #{_1}" }
          .join("\n")
      end
    end
  end
end
