# frozen_string_literal: true

module Baseline
  module Recurring
    class Base < ApplicationService
      def call
        check_uniqueness

        services_hash = services
          .compact
          .map {
            _1.is_a?(Array) ?
              [_1.first, _1.drop(1)] :
              [_1, []]
          }.to_h
          .reject {
            _1.new
              .try(:skippable?)
          }

        case
        when services_hash.one?
          service, args = services_hash.first
          service.call_async(*args)
        when services_hash.many?
          period = case self.class.name.demodulize
            when "Minutely" then 1.minute
            when "FiveMinutely",
                 "Hourly",
                 "ThreeHourly",
                 "Daily",
                 "Weekly" then 5.minutes
            else raise Error, "Unexpected service name: #{self.class.name}"
            end

          delay = period / (services_hash.size - 1)

          services_hash.each_with_index do |(service, args), index|
            service.call_in \
              delay * index,
              *args
          end
        end

        call_all_private_methods_without_args \
          except:       :services,
          raise_errors: false
      end

      private

        # Override with services to call.
        def services = []
    end
  end
end
