# frozen_string_literal: true

module Baseline
  module Avo
    module FieldHelpers
      def render_avo_button(url_or_action, icon:, title:)
        url, data =
          case url_or_action
          when Class
            unless url_or_action < ::Avo::BaseAction
              raise "Expected an Avo Action class, got #{url_or_action}"
            end
            url_or_action.link_arguments(resource:)
          when String
            [url_or_action, {}]
          else raise "Unexpected URL or action: #{url_or_action.class}"
          end

        data[:tippy] = :tooltip
        render ::Avo::ButtonComponent.new(
          url,
          icon:,
          title:,
          data:,
          style:   :outline,
          color:   :blue,
          size:    :xs,
          is_link: true
        )
      end
    end
  end
end
