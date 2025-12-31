# frozen_string_literal: true

module Baseline
  class AvatarBoxComponent < ApplicationComponent
    def initialize(imageable, size:, vertical: false, circle: true, image_wrapper: nil, data: nil)
      @imageable, @size, @vertical, @circle, @image_wrapper, @data =
        imageable, size, vertical, circle, image_wrapper, data

      @margin = {
        xs: 2,
        sm: 2,
        md: 3,
        lg: 3
      }.fetch(size, 4)
    end
  end
end
