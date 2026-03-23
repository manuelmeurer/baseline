# frozen_string_literal: true

module Baseline
  class GenerateHeaderImages < BaseService
    DIMENSIONS = {
      "3:1"   => [1200, 400],
      "16:9"  => [1200, 675],
      "4:3"   => [1200, 900],
      "1:1"   => [1200, 1200],
      "1.9:1" => [1200, 630]
    }.freeze

    ELEMENT_IDS = DIMENSIONS
      .keys
      .to_h { [_1, "header-#{_1.tr(".", "_")}"] }
      .freeze

    def call(record)
      html = ApplicationController.render(
        template: "baseline/header_images/preview",
        layout:   "baseline/admin_preview",
        assigns:  { record: }
      )

      record.header_images.purge

      DIMENSIONS.each do |name, (width, height)|
        path = External::BrowserScreenshot.generate(
          html,
          locator:  "##{ELEMENT_IDS[name]}",
          viewport: [width, height],
          save_to:  :file
        )

        record.header_images.attach(
          io:       File.open(path),
          filename: "header-#{name}.png"
        )

        File.delete(path)
      end
    end
  end
end
