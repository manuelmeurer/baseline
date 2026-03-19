# frozen_string_literal: true

module Baseline
  module External
    class BrowserScreenshot < ::External::Base
      DUMMY_URL = "https://weirdspace.info/RuneAndreasson/Graphics/Pellefant.gif".freeze
      SAVE_TO_DEFAULT = :web
      RETURN_UNLESS_PROD = ->(*_args, save_to: SAVE_TO_DEFAULT, **_kwargs) {
        case save_to
        when :web  then DUMMY_URL
        when :file then Baseline.dummy(:png).to_s
        else raise "Unexpected save_to: #{save_to}"
        end
      }.freeze

      add_action :generate, return_unless_prod: RETURN_UNLESS_PROD do |html, locator: nil, viewport: nil, save_to: SAVE_TO_DEFAULT, cache: false|
        unless save_to.in?(%i[web file])
          raise "Unexpected save_to: #{save_to}"
        end

        if cache
          cache_key = [
            :browser_screenshot,
            ActiveSupport::Digest.hexdigest(html),
            *[locator, viewport, save_to].map(&:to_s)
          ]
          if cached = Rails.cache.read(cache_key)
            return cached
          end
        end

        data = with_browser_page do |page|
          if viewport
            page.set_viewport_size \
              width:  viewport.first,
              height: viewport.last
          end
          page.set_content(html)
          page.wait_for_load_state(state: "networkidle")

          page
            .if(locator) { _1.locator(_2) }
            .screenshot
        end

        result =
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
              .to_s
          else
            raise "Unexpected save_to: #{save_to}"
          end

        if cache
          Rails.cache.write \
            cache_key,
            result,
            expires_in: cache
        end

        result
      end
    end
  end
end
