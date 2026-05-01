# frozen_string_literal: true

module Baseline
  module HasValueObjects
    def self.[](attribute, value_object_class,
      allow_duplicates:           true,
      duplicate_check_attributes: nil)

      Module.new do
        extend ActiveSupport::Concern

        included do
          validate do
            objects         = Array(public_send(attribute))
            invalid_objects = objects.select { _1.respond_to?(:invalid?) && _1.invalid? }

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
            values = defined?(super) ? super() : instance_variable_get("@#{attribute}")
            baseline_cast_value_objects(values, value_object_class)
          end
        end

        define_method "#{attribute}=" do |values|
          serialized_values = baseline_serialize_value_objects(values, value_object_class)

          if defined?(super)
            super(serialized_values)
          else
            instance_variable_set("@#{attribute}", serialized_values)
          end
        end

        define_method "#{attribute}_attributes=" do |attributes|
          values = attributes.values.select { _1.values.any?(&:present?) }
          public_send "#{attribute}=", values
        end

        define_method "add_#{attribute.to_s.singularize}" do |object_or_attributes = {}|
          object = Baseline::ValueObject.cast(object_or_attributes, value_object_class)
          public_send "#{attribute}=", public_send(attribute).push(object)
          object
        end

        private

          define_method :baseline_cast_value_objects do |values, value_object_class|
            return if values.nil?

            Array(values).map {
              Baseline::ValueObject.cast(_1, value_object_class)
            }
          end

          define_method :baseline_serialize_value_objects do |values, value_object_class|
            return if values.nil?

            Array(values).map {
              Baseline::ValueObject.serialize(_1, value_object_class)
            }
          end
      end
    end
  end
end
