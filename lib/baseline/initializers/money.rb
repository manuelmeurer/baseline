# frozen_string_literal: true

require "money-rails"

Money.setup_defaults
Money.default_currency = Money::Currency.new("EUR")
