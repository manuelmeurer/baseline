# frozen_string_literal: true

module Baseline
  class PreviewCardComponent < ApplicationComponent
    YOUTUBE_REGEX = %r{
      (?:
        youtube\.com/
        (?:
          watch\?v=|
          embed/|
          shorts/
        )|
        youtu\.be/
      )
      ([A-Za-z0-9_-]{11})
    }x.freeze

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
        require "baseline/services/external/microlink"

        @url           = helpers.normalize_url(@url)
        metadata       = External::Microlink.get_metadata(@url, cache: 1.year)
        @title         = metadata.fetch(:title)&.then { CGI.unescapeHTML(CGI.unescapeHTML(_1)) }
        @description   = metadata.fetch(:description)&.then { CGI.unescapeHTML(CGI.unescapeHTML(_1)) }
        @image_url     = metadata.dig(:image, :url)&.then { CGI.unescapeHTML(_1) }
        @website       = IdentifyURL.call(@url).name
        @website_image = External::LogoDev.get_url(@url, size: 30)
      end

      def before_render_youtube
        unless youtube_id = @url[YOUTUBE_REGEX, 1]
          raise "Could not determine YouTube ID from URL: #{@url}"
        end
        @url = "https://www.youtube.com/embed/#{youtube_id}"
      end
  end
end
