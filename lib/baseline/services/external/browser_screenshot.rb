# frozen_string_literal: true

module Baseline
  module External
    class BrowserScreenshot < ::External::Base
      DUMMY_URL = "https://weirdspace.info/RuneAndreasson/Graphics/Pellefant.gif".freeze

      add_action :generate, return_unless_prod: DUMMY_URL do |html, locator: nil, viewport: nil, save_to: :web|
        unless save_to.in?(%i[web file])
          raise ArgumentError, "Invalid save_to option: #{save_to}"
        end

        with_browser_page do |page|
          if viewport
            page.set_viewport_size \
              width:  viewport.first,
              height: viewport.last
          end
          page.set_content(html)
          page.wait_for_load_state(state: "networkidle")

          data = page
            .if(locator) { _1.locator(_2) }
            .screenshot

          case save_to
          when :web
            Cloudinary::Uploader.upload(
              StringIO.new(data),
              tags: %w[uplink tmp]
            ).fetch("secure_url")
          when :file
            Rails
              .root
              .join("tmp", "screenshots", "#{SecureRandom.hex(8)}.png")
              .tap { FileUtils.mkdir_p(_1.dirname) }
              .tap { File.binwrite(_1, data) }
          else
            raise "Unexpected save_to: #{save_to}"
          end
        end
      end
    end
  end
end
