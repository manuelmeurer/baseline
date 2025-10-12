# frozen_string_literal: true

module Baseline
  class CardComponent < ApplicationComponent
    def initialize(title: nil, image: nil, icon: nil, icon_position: :center, header: nil, css_class: nil, body_css_class: nil, icon_css_class: nil, equal_height: false, url: nil, footer: nil, footer_css_class: nil, title_tag: :h5, above_title: nil, after_body: nil, image_cover: false, data: {}, style: nil)
      @title, @image, @icon, @icon_position, @header, @css_class, @body_css_class, @icon_css_class, @equal_height, @url, @footer, @footer_css_class, @title_tag, @above_title, @after_body, @image_cover, @data, @style =
        title, image, icon, icon_position, header, css_class, body_css_class, icon_css_class, equal_height, url, footer, footer_css_class, title_tag, above_title, after_body, image_cover, data, style

      unless @icon_position.in?(%i[center left])
        raise ArgumentError, "icon_position must be :center or :left"
      end
    end

    def before_render
      @css_class       = class_names(:card, @css_class, "h-100": @equal_height)
      @image_css_class = class_names("card-img-top", "cover": @image_cover)
      @icon_css_class  = ["card-icon-#{@icon_position}", *@icon_css_class]
    end
  end
end
