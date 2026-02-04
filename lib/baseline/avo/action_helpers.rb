# frozen_string_literal: true

module Baseline
  module Avo
    module ActionHelpers
      private

        def process(query, condition: nil, success_message:, error_message: nil, &block)
          if query.blank?
            warn "No records selected."
            return
          end

          if condition
            matches, non_matches = query.partition(&condition)
          else
            matches = query
          end
          matches.each(&block)
          message = [
            ("#{pluralized(matches)} #{success_message}"   if matches.present?),
            ("#{pluralized(non_matches)} #{error_message}" if non_matches.present?)
          ].compact.join("\n")

          case
          when matches.blank?     then warn(message)
          when non_matches.blank? then succeed(message)
          else warn(message)
          end
        end

        def pluralized(records)
          records
            .first
            .class
            .model_name
            .human
            .if(records.many?) {
              ApplicationController.helpers.pluralize(records.size, _1.downcase)
            }
        end
    end
  end
end
