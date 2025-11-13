# frozen_string_literal: true

require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    include Baseline::ApplicationCore

    config.i18n.available_locales = %i[en de]
    config.i18n.default_locale    = config.i18n.available_locales.first
    config.i18n.fallbacks         = [I18n.default_locale]
  end
end
