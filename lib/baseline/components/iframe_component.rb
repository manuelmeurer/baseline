# frozen_string_literal: true

module Baseline
  class IframeComponent < ApplicationComponent
    RATIOS = %w[1x1 4x3 16x9 21x9]

    def initialize(url, ratio: nil, allow: nil)
      youtube = url.include?("youtube.com")

      @url   = url
      @ratio = ratio || (youtube ? "16x9"         : RATIOS.first)
      @allow = allow || (youtube ? %w[fullscreen] : %w[accelerometer autoplay clipboard-write encrypted-media gyroscope picture-in-picture web-share fullscreen])

      unless @ratio.in?(RATIOS)
        raise "#{@ratio} is not a valid ratio. Valid ratios are #{RATIOS.join(', ')}"
      end
    end
  end
end
