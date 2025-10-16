# frozen_string_literal: true

module Baseline
  class ListWithIconsComponent < ApplicationComponent
    renders_many :items, "ItemComponent"

    def initialize(css_class: nil)
      @css_class = css_class
    end

    def call
      tag.ul class: ["fa-ul", @css_class] do
        safe_join items, "\n"
      end
    end

    class ItemComponent < ApplicationComponent
      def initialize(icon: nil)
        @icon = icon
      end

      def call
        if @icon.is_a?(Array)
          unless @icon.size == 2 && @icon.last.is_a?(Hash)
            raise ArgumentError, "When passing an array as icon, it must be the icon identifier and options hash."
          end
          icon = component(:icon, @icon.first, **@icon.last)
        else
          icon = component(:icon, @icon)
        end

        tag.li do
          safe_join [
            tag.span(icon, class: "fa-li"),
            content
          ], " "
        end
      end
    end
  end
end
