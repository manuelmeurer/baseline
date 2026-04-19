# frozen_string_literal: true

module Baseline
  class GenerateHeaderImages < BaseService
    WIDTH = 1200
    VARIANTS = %w[3:1 16:9 4:3 1:1 40:21].to_h do |ratio|
      w, h = ratio.split(":").map(&:to_f)
      [ratio, [WIDTH, (WIDTH * h / w).round]]
    end.freeze

    def self.element_id(ratio) = "header-#{ratio.parameterize}"

    def call(record)
      html = ApplicationController.render(
        template: "baseline/header_images/preview",
        layout:   "baseline/admin_preview",
        assigns:  { record: }
      )

      record.header_images.purge

      VARIANTS.each do |ratio, (width, height)|
        [1, 2].each do |scale|
          path = External::BrowserScreenshot.generate(
            html,
            scale:,
            locator:  "##{self.class.element_id(ratio)}",
            viewport: [width, height],
            save_to:  :file
          )

          record.header_images.attach(
            io:       File.open(path),
            filename: "header-#{ratio}-w#{width * scale}.png"
          )

          File.delete(path)
        end
      end
    end
  end
end
