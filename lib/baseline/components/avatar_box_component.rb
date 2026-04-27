# frozen_string_literal: true

module Baseline
  class AvatarBoxComponent < ApplicationComponent
    def initialize(
      imageable,
      size:,
      align_items: :center,
      circle:      true,
      css_class:   nil,
      data:        nil,
      image_link:  nil,
      vertical:    false)

      # `image_link` accepts:
      # - a String: used as the link URL
      # - an Array: `[url, link_to_options_hash]`
      case image_link
      when nil, String
        @image_link_url, @image_link_options = image_link, {}
      when Array
        unless image_link.size == 2 && image_link.first.is_a?(String) && image_link.last.is_a?(Hash)
          raise ArgumentError, "Expected image_link to be [url, options_hash], got: #{image_link.inspect}"
        end
        @image_link_url, @image_link_options = image_link
      else
        raise ArgumentError, "Expected image_link to be a String or Array, got: #{image_link.inspect}"
      end

      @imageable, @size, @vertical, @circle, @data, @css_class, @align_items =
        imageable, size, vertical, circle, data, css_class, align_items
    end

    private

      def render_image(extra_class = nil)
        image =
          case @imageable
          when String
            helpers.image_tag @imageable, class: image_css_class(extra_class)
          when ActiveStorage::Attached, ActiveStorage::Blob
            if @imageable.try(:attached?) == false
              raise "Attachment is missing: #{@imageable.id}"
            end
            helpers.component(:attachment_image, @imageable, :md_thumb, class: image_css_class(extra_class))
          else
            raise "Unexpected @imageable: #{@imageable.class}"
          end

        if @image_link_url
          helpers.link_to image, @image_link_url, **@image_link_options.deep_merge(class: "shrink-0")
        else
          image
        end
      end

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
