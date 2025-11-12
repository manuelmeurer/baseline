# frozen_string_literal: true

module Baseline
  module HasEnumArray
    def self.[](attribute)
      singular_attribute = attribute.to_s.singularize.to_sym
      valid_method_name  = :"valid_#{attribute}"

      Module.new do
        extend ActiveSupport::Concern

        define_singleton_method :enum_array_attribute do
          attribute
        end

        included do
          validates attribute, array_uniqueness: true

          validate do
            if invalids = public_send(attribute).difference(self.class.public_send(valid_method_name)).presence
              errors.add attribute, message: "contain invalid elements: #{invalids.join(", ")}"
            end
          end
        end

        define_method "#{attribute}=" do |value|
          super Array(value).map(&:to_s)
        end

        define_method "add_#{singular_attribute}" do |value|
          update! attribute => public_send(attribute).union([value.to_s])
        end

        define_method "remove_#{singular_attribute}" do |value|
          update! attribute => public_send(attribute).excluding(value.to_s)
        end

        define_method "has_#{singular_attribute}?" do |value|
          valid_values = self.class.public_send(valid_method_name)
          if valid_values.exclude?(value.to_s)
            raise "#{value} is not a valid value for #{attribute}, valid are: #{valid_values.join(", ")}}"
          end

          public_send(attribute).include?(value.to_s)
        end
      end
    end
  end
end
