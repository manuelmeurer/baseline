# frozen_string_literal: true

class AvatarBoxComponent < ApplicationComponent
  def initialize(imageable, size:, vertical: false, rounded_corners: true, image_wrapper: nil)
    @imageable, @size, @vertical, @rounded_corners, @image_wrapper =
      imageable, size, vertical, rounded_corners, image_wrapper
    @margin = size.in?(%i[xs sm]) ? 2 : 3
  end
end
