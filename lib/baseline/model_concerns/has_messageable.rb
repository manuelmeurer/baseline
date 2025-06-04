# frozen_string_literal: true

module Baseline
  module HasMessageable
    extend ActiveSupport::Concern

    included do
      belongs_to :messageable, polymorphic: true, optional: true
    end

    class_methods do
      def validate_messageable(kind_messageable_classes)
        validate if: :kind do
          # Keys of `kind_messageable_classes` can be symbols or regexes.
          messageable_class = kind_messageable_classes
            .detect { _1.first === kind.to_sym }
            &.last ||
              NilClass
          unless messageable.is_a?(messageable_class)
            expected, actual = [messageable_class, messageable.class].map { _1.nil? ? "nil" : "a #{_1}" }
            errors.add :messageable, message: "must be #{expected} but is #{actual}"
          end
        end
      end
    end
  end
end
