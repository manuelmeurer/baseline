# frozen_string_literal: true

module Baseline
  module HasAssociationWithPosition
    def self.[](association)
      attribute = :"sorted_#{association.to_s.singularize}_ids"

      Module.new do
        extend ActiveSupport::Concern

        included do
          attr_reader attribute

          after_commit do
            value   = public_send(attribute)
            records = public_send(association)

            if value.present?
              # Move positions up so we don't get an uniqueness error when we update them.
              records.update_all "position = position + #{records.size}"

              records.each_with_index do |record, index|
                position = (
                  value.index(record.id) ||
                  value.size + index
                ) + 1
                record.update!(position:)
              end
            end
          end

          define_method "#{attribute}=" do |value|
            if value.is_a?(String)
              value = value
                .split(",")
                .map(&:strip)
                .compact_blank
                .map(&:to_i)
            end

            instance_variable_set "@#{attribute}", value
          end

          define_method "#{association}=" do |value|
            value&.each_with_index do |record, index|
              record.position = index + 1
            end

            super(value)
          end
        end
      end
    end
  end
end
