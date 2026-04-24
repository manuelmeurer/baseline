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
    end

    private

      def image_css_class(extra = nil)
        [
          extra,
          "border",
          *variant_image_classes
        ].compact.join(" ")
      end

      def container_css_class
        if Current.tailwind
          [@css_class, "flex", "items-#{@align_items}", ("flex-col" if @vertical), gap_css_class]
        else
          [@css_class, "d-flex", "align-items-#{@align_items}", ("flex-column" if @vertical)]
        end.compact.join(" ")
      end

      # Only used in Bootstrap mode; Tailwind gets spacing via `gap` on the container
      # so the space is preserved even when the image is wrapped (e.g. in a link).
      def margin_css_class
        return if Current.tailwind

        axis  = @vertical ? "mb" : "me"
        scale = { xs: 2, sm: 2, md: 3, lg: 3 }.fetch(@size, 4)
        "#{axis}-#{scale}"
      end

      def gap_css_class
        scale = { xs: 2, sm: 2, md: 4, lg: 4 }.fetch(@size, 6)
        "gap-#{scale}"
      end

      def variant_image_classes
        if Current.tailwind
          [
            "border-base-300",
            "object-cover",
            "shrink-0",
            tailwind_size_class,
            ("rounded-full" if @circle)
          ]
        else
          [
            "object-fit-cover",
            "square-#{@size}",
            ("rounded-circle" if @circle)
          ]
        end.compact
      end

      def tailwind_size_class
        {
          xs: "size-[30px]",
          sm: "size-[40px]",
          md: "size-[80px]",
          lg: "size-[120px]",
          xl: "size-[200px]"
        }.fetch(@size)
      end
  end
end
