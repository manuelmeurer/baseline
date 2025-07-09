# frozen_string_literal: true

require "money-rails"

Money.locale_backend = :i18n

MoneyRails.configure do |config|
  config.default_currency = :eur
end
