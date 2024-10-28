# frozen_string_literal: true

module Baseline
  module ControllerExtensions
    extend ActiveSupport::Concern

    included do
      helper_method def specific_turbo_frame_request?(name_or_resource)
        name_or_resource
          .if(ActiveRecord::Base) { helpers.dom_id(_1) }
          .then { turbo_frame_request_id == _1.to_s }
      end

      helper_method def normalized_action_name(action = Current.action_name, reverse: false)
        {
          "create" => "new",
          "update" => "edit"
        }.if(reverse, &:invert)
          .fetch(action) {
            action.delete_prefix("do_")
          }
      end

      helper_method def stimco(name, to_h: true, outlets: {}, **values)
        StimulusController
          .new(name:, values:, outlets:)
          .if(to_h) { _1.to_h }
      end
    end

    private

      def add_flash(type, text, now: false)
        valid_types = %i(alert info notice warning)
        unless type.in?(valid_types)
          raise "type is not valid, must be one of: #{valid_types.join(", ")}"
        end

        desired_flash = now ?
                        flash.now :
                        flash

        desired_flash[type] = [
          desired_flash[type],
          text
        ].compact_blank
         .join("\n\n")
      end

      def html_redirect_to(options = {}, response_options = {})
        response_options[:status] ||= :see_other

        respond_to do |format|
          format.html do
            redirect_to options, response_options
          end
        end
      end

      def html_redirect_back_or_to(url, params = {})
        respond_to do |format|
          format.html do
            redirect_back \
              fallback_location: url,
              status:            :see_other,
              **params
          end
        end
      end
  end
end
