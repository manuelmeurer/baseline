# frozen_string_literal: true

require "geocoder"

Geocoder.configure \
  cache:        Geocoder::CacheStore::Generic.new(Rails.cache, {}),
  language:     :de,
  logger:       Rails.logger,
  units:        :km,
  always_raise: :all,
  lookup:       :google,
  google: {
    use_https: true,
    api_key:   Rails.application.env_credentials.google.geocode_api_key
  }
