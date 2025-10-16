# frozen_string_literal: true

module Baseline
  class ItemListComponent < ApplicationComponent
    DEFAULT_GAP = {
      row:    1,
      column: 4
    }

    renders_many :items, "ItemComponent"

    def initialize(breakpoint: :sm, center_vertically: false, css_class: nil, gap: nil)
      @breakpoint, @center_vertically, @css_class =
        breakpoint, center_vertically, css_class

      @gap =
        case gap
        when Integer  then { row: gap, column: gap }
        when Hash     then gap.reverse_merge(DEFAULT_GAP)
        when NilClass then DEFAULT_GAP
        else raise "Unexpected gap: #{gap}"
        end
    end

    def call
      css_class = class_names(
        *@css_class,
        "d-flex",
        "flex-column",
        "row-gap-#{@gap.fetch(:row)}",
        "column-gap-#{@gap.fetch(:column)}",
        "flex-#{@breakpoint}-row" => @breakpoint,
        "align-items-#{@breakpoint}-center" => @breakpoint && @center_vertically
      )

      tag.div class: css_class do
        safe_join items, " "
      end
    end

    class ItemComponent < ApplicationComponent
      def initialize(icon: nil, css_class: nil, data: nil)
        @icon, @css_class, @data =
          icon, css_class, data
      end

      def call
        tag.span class: @css_class, data: @data do
          safe_join [
            @icon&.then { component(:icon, *_1, fixed_width: true) },
            content
          ], " "
        end
      end
    end
  end
end
