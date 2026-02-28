# frozen_string_literal: true

module Baseline
  class CardComponent < ApplicationComponent
    def initialize(title: nil, image: nil, icon: nil, icon_position: :center, header: nil, header_css_class: nil, header_data: {}, css_class: nil, body_css_class: nil, icon_css_class: nil, equal_height: false, url: nil, footer: nil, footer_css_class: nil, title_tag: nil, above_title: nil, after_body: nil, image_cover: false, horizontal: false, data: {}, style: nil)
      @title, @image, @icon, @icon_position, @header, @header_css_class, @header_data, @css_class, @body_css_class, @icon_css_class, @equal_height, @url, @footer, @footer_css_class, @title_tag, @above_title, @after_body, @image_cover, @horizontal, @data, @style =
        title, image, icon, icon_position, header, header_css_class, header_data, css_class, body_css_class, icon_css_class, equal_height, url, footer, footer_css_class, title_tag.if(NilClass, :h5), above_title, after_body, image_cover, horizontal, data, style

      unless @icon_position.in?(%i[center left])
        raise ArgumentError, "icon_position must be :center or :left"
      end

      unless @title_tag.to_s.match?(/\Ah\d\z/)
        raise ArgumentError, "title_tag must be a heading tag (h1-h6)"
      end
    end

    def before_render
      @css_class = class_names(:card, @css_class, "h-100": @equal_height)
      @icon_css_class = ["card-icon-#{@icon_position}", *@icon_css_class]
      @image_css_class =
        @horizontal ?
          class_names("img-fluid", "rounded-start") :
          class_names("card-img-top", "cover": @image_cover, "height-#{@image_cover.unless(Integer, 200)}": @image_cover)

      if @horizontal
        image_col = @horizontal.unless(Integer, 4)
        @horizontal_image_css_class = "col-md-#{image_col}"
        @horizontal_body_css_class  = "col-md-#{12 - image_col}"
      end
    end
  end
end
