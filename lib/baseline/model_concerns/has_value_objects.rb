# frozen_string_literal: true

module Baseline
  module HasValueObjects
    def self.[](attribute, klass, allow_duplicates: true, duplicate_check_attributes: nil)
      Module.new do
        extend ActiveSupport::Concern

        included do
          validate do
            objects         = public_send(attribute)
            invalid_objects = objects.select(&:invalid?)

            case
            when invalid_objects.any?
              errors.add \
                attribute,
                :invalid,
                details: invalid_objects.map { _1.errors.full_messages }.join(", "),
                count:   2
            when !allow_duplicates
              duplicate_check_objects =
                duplicate_check_attributes ?
                  objects.map do |object|
                    Array(duplicate_check_attributes).map {
                      object.public_send(_1)
                    }
                  end :
                  objects

              if duplicate_check_objects
                  .tally
                  .values
                  .any? { _1 > 1 }

                errors.add attribute, :has_duplicates
              end
            end
          end

          # This needs to be defined in the `included` block, otherwise it will not work
          # when HasValueObjects is included in non-AR classes that use `ActiveModel::Model`.
          define_method attribute do
            objects = defined?(super) ? super() : instance_variable_get("@#{attribute}")
            objects&.map { klass.new _1.try(:except, "errors") }
          end
        end

        define_method "#{attribute}_attributes=" do |attributes|
          values = attributes.values.select { _1.values.any?(&:present?) }
          public_send "#{attribute}=", values.map { klass.new _1 }
        end

        define_method "add_#{attribute.to_s.singularize}" do |object_or_attributes = {}|
          object = object_or_attributes.is_a?(Hash) ?
                   klass.new(object_or_attributes) :
                   object_or_attributes
          public_send "#{attribute}=", public_send(attribute).push(object)
          object
        end
      end
    end
  end
end
