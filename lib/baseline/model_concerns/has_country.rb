# frozen_string_literal: true

module Baseline
  module HasCountry
    extend ActiveSupport::Concern

    included do
      composed_of :country,
        class_name: ISO3166::Country.to_s,
        mapping:    %w[country alpha2],
        converter:  ISO3166::Country.method(:new)
    end

    def germany?                   = country == ISO3166::Country["DE"]
    def eu_country?                = country.data["eu_member"]
    def eu_country_except_germany? = eu_country? && !germany?
  end
end
