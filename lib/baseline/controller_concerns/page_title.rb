# frozen_string_literal: true

module Baseline
  module PageTitle
    class << self
      def [](default_method = nil)
        Module.new do
          extend ActiveSupport::Concern

          included do
            private

              define_method :page_title do
                t(:title, **page_title_attributes, scope: page_title_scope, default: nil) ||
                  default_method&.then { send _1 } ||
                  controller_name.titleize
              end.then {
                helper_method _1
              }
          end

          private

            def page_title_attributes = {}
            def page_title_scope      = action_i18n_scope
        end
      end

      def included(base)
        base.include self[]
      end
    end
  end
end
