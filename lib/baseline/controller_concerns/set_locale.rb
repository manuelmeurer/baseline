# frozen_string_literal: true

module Baseline
  module SetLocale
    class << self
      def [](locale_proc = nil)
        Module.new do
          extend ActiveSupport::Concern

          included do
            around_action do |_, block|
              locale =
                params[:locale] ||
                cookies[:locale] ||
                locale_proc&.call ||
                locale_from_accept_language_header

              locale = locale&.to_sym

              unless locale&.in?(I18n.available_locales)
                locale = I18n.default_locale
              end

              cookies.permanent[:locale] = {
                value:  locale,
                secure: Rails.configuration.force_ssl
              }

              I18n.with_locale locale, &block
            end

            private

              def locale_from_accept_language_header
                request.headers["Accept-Language"]
                  &.split(",")
                  &.map { _1.split(";").first }
                  &.detect { I18n.available_locales.include?(_1.to_sym) }
              end
          end
        end
      end

      def included(base)
        base.include self[]
      end
    end
  end
end
