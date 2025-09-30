# frozen_string_literal: true

module Baseline
  class AvatarBoxComponent < ApplicationComponent
    def initialize(imageable, size:, vertical: false, rounded_corners: true, image_wrapper: nil, data: nil)
      @imageable, @size, @vertical, @rounded_corners, @image_wrapper, @data =
        imageable, size, vertical, rounded_corners, image_wrapper, data

      @margin = {
        xs: 2,
        sm: 2,
        md: 3,
        lg: 3
      }.fetch(size, 4)
    end
  end
end
