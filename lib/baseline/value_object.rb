# frozen_string_literal: true

module Baseline
  module ValueObject
    def self.cast(value, value_object_class)
      return if value.nil?
      return value if value.is_a?(value_object_class)

      if value.is_a?(Hash) || value.respond_to?(:to_unsafe_h)
        attributes = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value
        attributes = attributes.except("errors", :errors)

        return value_object_class.from_h(attributes) if value_object_class.respond_to?(:from_h)

        build_from_hash(attributes, value_object_class)
      else
        value_object_class.new(value)
      end
    end

    def self.serialize(value, value_object_class)
      return if value.nil?

      cast(value, value_object_class).then do |object|
        case
        when object.respond_to?(:to_h)
          object.to_h
        when object.respond_to?(:attributes)
          object.attributes
        else
          object
        end
      end
    end

    def self.build_from_hash(attributes, value_object_class)
      uses_keyword_arguments =
        (defined?(Data) && value_object_class < Data) ||
        value_object_class
          .instance_method(:initialize)
          .parameters
          .any? { %i[key keyreq keyrest].include?(_1.first) }

      if uses_keyword_arguments
        value_object_class.new(**attributes)
      else
        value_object_class.new(attributes)
      end
    end
  end
end
