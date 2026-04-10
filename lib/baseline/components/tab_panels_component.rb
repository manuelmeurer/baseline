# frozen_string_literal: true

module Baseline
  class TabPanelsComponent < ApplicationComponent
    renders_many :panels, "PanelComponent"

    # Listed as literal strings so Tailwind's content scanner picks them up —
    # building the class name dynamically would leave them out of the compiled CSS.
    STYLE_CSS_CLASSES = {
      box:    "tabs-box",
      border: "tabs-border",
      lift:   "tabs-lift"
    }.freeze

    def initialize(gap: 3, style: (Current.tailwind ? :lift : :tabs), content_css_class: nil, nav_css_class: nil)
      @id = "panels-#{SecureRandom.hex(3)}"
      @style, @nav_css_class, @content_css_class =
        style, nav_css_class, content_css_class
      if gap
        @content_css_class = Array(@content_css_class) << "mt-#{gap}"
      end
    end

    def style_css_class = STYLE_CSS_CLASSES.fetch(@style)

    class PanelComponent < ApplicationComponent
      attr_reader :id, :title, :icon, :css_class, :nav_css_class

      def initialize(title:, icon: nil, css_class: nil, nav_css_class: nil)
        @id = "panel-#{SecureRandom.hex(3)}"
        @title, @icon, @css_class, @nav_css_class =
          title, icon, css_class, nav_css_class
      end

      # All components must have a `call` method or a template, even if it's not used.
      def call; end
    end
  end
end
