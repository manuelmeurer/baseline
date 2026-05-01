# frozen_string_literal: true

module Baseline
  module HasValueObject
    def self.[](attribute, value_object_class)
      Module.new do
        extend ActiveSupport::Concern

        included do
          validate do
            object = public_send(attribute)
            next unless object&.respond_to?(:invalid?)
            next unless object.invalid?

            errors.add \
              attribute,
              :invalid,
              details: object.errors.full_messages.join(", "),
              count:   1
          end

          # This needs to be defined in the `included` block, otherwise it will not work
          # when HasValueObject is included in non-AR classes that use `ActiveModel::Model`.
          define_method attribute do
            value = defined?(super) ? super() : instance_variable_get("@#{attribute}")
            Baseline::ValueObject.cast(value, value_object_class)
          end
        end

        define_method "#{attribute}=" do |value|
          serialized_value = Baseline::ValueObject.serialize(value, value_object_class)

          if defined?(super)
            super(serialized_value)
          else
            instance_variable_set("@#{attribute}", serialized_value)
          end
        end

        define_method "#{attribute}_attributes=" do |attributes|
          value = attributes if attributes.values.any?(&:present?)
          public_send "#{attribute}=", value
        end
      end
    end
  end
end
