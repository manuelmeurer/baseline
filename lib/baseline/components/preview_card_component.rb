# frozen_string_literal: true

module Baseline
  class PreviewCardComponent < ApplicationComponent
    def initialize(url)
      @url = url
      @id  = "preview-card-#{SecureRandom.hex(3)}"
    end

    def before_render
      @type =
        case @url
        when /youtube\.com/ then :youtube
        else :card
        end

      suppress NoMethodError do
        send "before_render_#{@type}"
      end
    end

    private

      def before_render_card
        require "baseline/services/external/link_metadata"

        @url         = helpers.normalize_url(@url)
        metadata     = External::LinkMetadata.get_metadata(@url, cache: 1.year)
        @title       = metadata.fetch(:title)&.then { CGI.unescapeHTML(CGI.unescapeHTML(_1)) }
        @description = metadata.fetch(:description)&.then { CGI.unescapeHTML(CGI.unescapeHTML(_1)) }
        @image_url   = metadata.dig(:image, :url)&.then { CGI.unescapeHTML(_1) }
        @website     = IdentifyURL.call(@url).name
      end

      def before_render_youtube
        unless youtube_id = @url[%r{/watch\?v=(.+)}, 1]
          raise "Could not determine YouTube ID from URL: #{@url}"
        end
        @url = "https://www.youtube.com/embed/#{youtube_id}"
      end
  end
end
