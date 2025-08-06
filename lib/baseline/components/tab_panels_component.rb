# frozen_string_literal: true

module Baseline
  class TabPanelsComponent < ApplicationComponent
    renders_many :panels, "PanelComponent"

    def initialize(gap: 3, style: :tabs, content_css_class: nil, nav_css_class: nil)
      @style, @nav_css_class, @content_css_class =
        style, nav_css_class, content_css_class
      if gap
        @content_css_class = Array(@content_css_class) << "mt-#{gap}"
      end
    end

    class PanelComponent < ApplicationComponent
      attr_reader :id, :title, :css_class, :nav_css_class

      def initialize(title:, css_class: nil, nav_css_class: nil)
        @id = "panel-#{SecureRandom.hex(3)}"
        @title, @css_class, @nav_css_class =
          title, css_class, nav_css_class
      end

      # All components must have a `call` method or a template, even if it's not used.
      def call; end
    end
  end
end
