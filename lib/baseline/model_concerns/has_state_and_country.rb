# frozen_string_literal: true

module Baseline
  module HasStateAndCountry
    extend ActiveSupport::Concern

    included do
      include Baseline::HasCountry

      enum :state, %i[
        Baden-Württemberg
        Bayern
        Berlin
        Brandenburg
        Bremen
        Hamburg
        Hessen
        Mecklenburg-Vorpommern
        Niedersachsen
        Nordrhein-Westfalen
        Rheinland-Pfalz
        Saarland
        Sachsen
        Sachsen-Anhalt
        Schleswig-Holstein
        Thüringen
      ]

      validates :country, presence: true
      validates :state,
        presence: {
          if:      -> { geocoded? && germany? },
          message: "must be present if country is Germany"
        },
        absence:  {
          unless:  :germany?,
          message: "must be absent if country is not Germany"
        }
    end
  end
end
