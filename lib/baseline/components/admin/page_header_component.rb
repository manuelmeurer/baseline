# frozen_string_literal: true

module Baseline
  module Admin
    class PageHeaderComponent < ApplicationComponent
      renders_one :actions

      def initialize(title:, subtitle: nil, css_class: nil)
        @title, @subtitle, @css_class =
          title, subtitle, css_class
      end
    end
  end
end
