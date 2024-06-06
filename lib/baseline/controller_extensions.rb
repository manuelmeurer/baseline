module Baseline
  module ControllerExtensions
    extend ActiveSupport::Concern

    included do
      helper_method def specific_turbo_frame_request?(name_or_resource)
        if name_or_resource.is_a?(ActiveRecord::Base)
          name_or_resource = helpers.dom_id(name_or_resource)
        end
        turbo_frame_request_id == name_or_resource.to_s
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
