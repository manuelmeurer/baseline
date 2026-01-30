# frozen_string_literal: true

module Baseline
  module ActsAsLocation
    extend ActiveSupport::Concern

    included do
      include HasStateAndCountry,
              TouchAsync[:locationable]

      geocoded_by :address

      belongs_to :city, optional: true
      belongs_to :locationable, polymorphic: true, optional: true

      validates :address, presence: true
      validates :url, url_format: { allow_blank: true }
      validates :longitude, presence: { if: :latitude }
      validates :state, inclusion: { in: -> { [_1.city.state] }, if: :city, message: "must be the city's state" }
      validates :name, presence: { if: -> { locationable.is_a?(Event) }, message: "can't be blank for event locations" }
      validates :locationable_id,
        uniqueness: {
          scope:     %i[locationable_type latitude longitude],
          allow_nil: true,
          message:   :duplicate
        }

      validate do
        if address.present? && !latitude
          errors.add :address, :geocoding_failed
        end
        if country.present? && city&.country.present? && country != city.country
          errors.add :country, message: "must be the same as the country of city #{city}, namely #{city.country}"
        end
      end
    end

    class_methods do
      def clone_fields
        %i[
          address
          country
          latitude
          longitude
          name
          state
          url
          zip
        ] + [{
          city: :copy
        }]
      end

      def search(query)
        ransack(
          name_cont:    query,
          address_cont: query,
          m:            "or"
        ).result \
          distinct: false
      end
    end

    def to_s
      if name
        [
          name,
          [zip, city].compact_blank.join(" ")
        ].compact_blank.join(", ")
      else
        address
      end
    end

    def name_and_city
      [name, city].compact_blank.join(" ")
    end

    def zip_and_city_or_state
      [zip, city]
        .compact_blank
        .join(" ")
        .presence ||
          state
    end

    def google_maps_url
      "http://maps.google.com/maps?q=#{CGI.escape to_s}"
    end
  end
end
