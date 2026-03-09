# frozen_string_literal: true

module Baseline
  class AvatarBoxComponent < ApplicationComponent
    def initialize(
      imageable,
      size:,
      align_items:   :center,
      circle:        true,
      css_class:     nil,
      data:          nil,
      image_wrapper: nil,
      vertical:      false)

      @imageable, @size, @vertical, @circle, @image_wrapper, @data, @css_class, @align_items =
        imageable, size, vertical, circle, image_wrapper, data, css_class, align_items

      @margin = {
        xs: 2,
        sm: 2,
        md: 3,
        lg: 3
      }.fetch(size, 4)
    end
  end
end
