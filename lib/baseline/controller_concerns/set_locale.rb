# frozen_string_literal: true

module Baseline
  module SetLocale
    extend ActiveSupport::Concern

    included do
      around_action do |_, block|
        locale =
          params[:locale] ||
          cookies[:locale] ||
          ::Current.user&.locale ||
          AcceptLanguage
            .parse(request.headers["Accept-Language"].to_s)
            .match(*I18n.available_locales)

        locale = locale&.to_sym

        unless locale&.in?(I18n.available_locales)
          locale = I18n.default_locale
        end

        I18n.with_locale locale, &block
      end
    end
  end
end
