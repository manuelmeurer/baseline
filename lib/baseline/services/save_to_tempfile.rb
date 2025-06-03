# frozen_string_literal: true

module Baseline
  class SaveToTempfile < ApplicationService
    def call(attachment_or_content)
      content, encoding =
        attachment_or_content.is_a?(String) ?
          [attachment_or_content,          attachment_or_content.encoding] :
          [attachment_or_content.download, "ascii-8bit"]

      Tempfile
        .create(encoding:)
        .tap {
          _1.write content
          _1.rewind
        }
    end
  end
end
