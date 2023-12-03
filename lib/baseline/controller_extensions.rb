module Baseline
  module ControllerExtensions
    extend ActiveSupport::Concern

    included do
      require "turbo/version"
      if Turbo::VERSION >= "2.0"
        raise "check if `turbo_frame_request?` is now added as a helper method in the gem: https://github.com/hotwired/turbo-rails/blob/main/app/controllers/turbo/frames/frame_request.rb"
      end
      helper_method :turbo_frame_request?
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
