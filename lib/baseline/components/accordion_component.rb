# frozen_string_literal: true

module Baseline
  class AccordionComponent < ApplicationComponent
    renders_many :items, "ItemComponent"

    def initialize(id, expanded: true, css_class: nil, header_button_css_class: nil)
      @id, @expanded, @css_class, @header_button_css_class =
        id, expanded, css_class, header_button_css_class
    end

    class ItemComponent < ApplicationComponent
      attr_reader :title

      def initialize(title:)
        @title = title
      end

      # All components must have a `call` method or a template, even if it's not used.
      def call; end
    end
  end
end
