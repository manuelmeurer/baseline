# frozen_string_literal: true

module Baseline
  class GenerateHeaderImages < BaseService
    DIMENSIONS = {
      "3:1"   => { 1200 => 400 },
      "16:9"  => { 1200 => 675, 3840 => 2160 },
      "4:3"   => { 1200 => 900 },
      "1:1"   => { 1200 => 1200 },
      "1.9:1" => { 1200 => 630 }
    }.freeze
    ELEMENT_IDS = DIMENSIONS
      .flat_map do |name, sizes|
        sizes.keys.map { [[name, _1], "header-#{name.tr(":", "-")}-w#{_1}"] }
      end
      .to_h
      .freeze

    def call(record)
      html = ApplicationController.render(
        template: "baseline/header_images/preview",
        layout:   "baseline/admin_preview",
        assigns:  { record: }
      )

      record.header_images.purge

      DIMENSIONS.each do |name, sizes|
        sizes.each do |width, height|
          path = External::BrowserScreenshot.generate(
            html,
            locator:  "##{ELEMENT_IDS.fetch([name, width])}",
            viewport: [width, height],
            save_to:  :file
          )

          record.header_images.attach(
            io:       File.open(path),
            filename: "header-#{name}-w#{width}.png"
          )

          File.delete(path)
        end
      end
    end
  end
end
