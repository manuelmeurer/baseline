# frozen_string_literal: true

module Baseline
  class Geocode < ApplicationService
    def call(geocodable)
      return geocodable if geocodable.geocoded?

      geocodable.send :do_lookup, false do |_, results|
        address = geocodable
          .class
          .geocoder_options
          .fetch(:user_address)
          .then { geocodable.public_send _1 }

        unless result = results.first
          ReportError.call(
            Error,
            "Cound not geocode #{geocodable.class}.",
            geocodable_gid: geocodable.then { _1.to_gid.to_s if _1.persisted? },
            address:
          )
          return geocodable
        end

        unless country_code = result.country_code.presence
          raise Error, "Cound not find country code in geocoding result.",
            result:         result.inspect,
            geocodable_gid: geocodable.to_gid.to_s,
            address:
        end

        unless geocodable.country = ISO3166::Country[country_code]
          raise Error, "Cound not find country for country code.",
            country_code:,
            result:         result.inspect,
            geocodable_gid: geocodable.to_gid.to_s,
            address:
        end

        if geocodable.germany?
          state = result.state ||
            ("Baden-Württemberg" if result.city == "Mannheim") # Google Maps API sometimes doesn't return the state for Mannheim
          case
          when !state
            raise Error, "State for address in Germany not found: #{address}"
          when City.states.keys.exclude?(state)
            state = t(state, scope: :german_states, locale: :en, default: nil) or
              raise Error, "Invalid state in geocoding result: #{address}"
          end
        end

        # All checks whether the geocoding result is valid
        # should be done before assigning the latitude and longitude.
        geocodable.latitude, geocodable.longitude = result.latitude, result.longitude

        if geocodable.respond_to?(:zip)
          geocodable.zip = result.postal_code
        end

        if geocodable.respond_to?(:city)
          if city = result.city
            if state
              t(state, scope: :city_aliases, locale: :en, default: {})
                .values
                .detect { _1.include?(city) }
                &.then {
                  city = _1.first
                }
            end

            City
              .where(
                name:    city,
                state:,
                country: geocodable.country
              ).first_or_initialize do |city|
                self.class.call city
                city.save!
              end.then {
                geocodable.city = _1
              }
          end
        end

        geocodable.state = geocodable.try(:city)&.state || state
      end

      geocodable
    end
  end
end
