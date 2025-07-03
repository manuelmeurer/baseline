# frozen_string_literal: true

module Baseline
  class CardComponent < ApplicationComponent
    def initialize(title: nil, image: nil, icon: nil, header: nil, css_class: nil, body_css_class: nil, equal_height: false, url: nil, footer: nil, footer_css_class: nil, title_tag: :h5, above_title: nil, after_body: nil, image_cover: false, data: {}, style: nil)
      @title, @image, @icon, @header, @css_class, @body_css_class, @equal_height, @url, @footer, @footer_css_class, @title_tag, @above_title, @after_body, @image_cover, @data, @style =
        title, image, icon, header, css_class, body_css_class, equal_height, url, footer, footer_css_class, title_tag, above_title, after_body, image_cover, data, style
    end

    def before_render
      @css_class       = class_names(:card, @css_class, "h-100": @equal_height)
      @image_css_class = class_names("card-img-top", "cover": @image_cover)
    end
  end
end
