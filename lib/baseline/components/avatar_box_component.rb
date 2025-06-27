# frozen_string_literal: true

class AvatarBoxComponent < ApplicationComponent
  def initialize(imageable, size:, vertical: false, rounded_corners: true, image_wrapper: nil)
    @imageable, @size, @vertical, @rounded_corners, @image_wrapper =
      imageable, size, vertical, rounded_corners, image_wrapper

    @margin = {
      xs: 2,
      sm: 2,
      md: 3,
      lg: 3
    }.fetch(size, 4)
  end
end
