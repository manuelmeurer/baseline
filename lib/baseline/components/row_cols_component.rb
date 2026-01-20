# frozen_string_literal: true

module Baseline
  class RowColsComponent < ApplicationComponent
    renders_many :cols, "ColComponent"

    def initialize(cols: nil, gutter: nil, css_class: nil, id: nil, data: nil)
      if css_class&.if(Array) { _1.join(" ") }&.match?(/\bm[ty]?-/)
        raise "Don't set a top margin on row cols, it messes up the negative top margin that is added by Bootstrap to offset the gutter."
      end

      cols   ||= { sm: 2, lg: 3, xl: 4 }
      gutter ||= { nil => 3, md: 4 }

      @id, @data = id, data
      @css_class = gutter
        .if(Integer, { nil => gutter })
        .map { ["g", _1, _2].compact.join("-") }
        .concat(cols.map { ["row-cols", _1, _2].join("-") })
        .push("row", "row-cols-1", *@css_class)
    end

    def call
      tag.div class: @css_class, id: @id, data: @data do
        content
      end
    end

    class ColComponent < ApplicationComponent
      def call
        tag.div class: "col" do
          content
        end
      end
    end
  end
end
