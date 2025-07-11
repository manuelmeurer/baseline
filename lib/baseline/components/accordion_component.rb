# frozen_string_literal: true

module Baseline
  class AccordionComponent < ApplicationComponent
    renders_many :items, "ItemComponent"

    def initialize(id, expanded: true)
      @id, @expanded = id, expanded
    end

    class ItemComponent < ViewComponent::Base
      attr_reader :title, :body

      def initialize(title:, body:)
        @title, @body = title, body
      end
    end
  end
end
