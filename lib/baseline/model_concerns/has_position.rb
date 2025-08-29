# frozen_string_literal: true

module Baseline
  module HasPosition
    def self.[](*uniqueness_scope_parts)
      Module.new do
        extend ActiveSupport::Concern

        included do
          after_initialize do
            next unless new_record? && position.nil?

            associations = Array(uniqueness_scope_parts).map { self.class.reflect_on_association _1 }

            if associations.any?(&:nil?)
              raise "Expected all the uniqueness scope parts to be associations. Setting the default position needs to be handled differently when non-association attributes are used."
            end

            next if associations.any? { public_send(_1.name).blank? }

            scopes = associations.map do |association|
              unless inverse_association = association.has_inverse?
                raise "Cannot determine inverse association for #{self.class}##{association.name}."
              end
              public_send(association.name).public_send(inverse_association)
            end

            self.position = scopes
              .inject(:merge)
              .to_a # to_a is necessary so that unsaved records are taken into account as well
              .maximum(:position)
              .then { (_1 || 0) + 1 }
          end

          uniqueness_scope = Array(uniqueness_scope_parts).flat_map do |part|
            reflection = reflect_on_association(part)
            if reflection && !reflection.belongs_to?
              raise "Cannot use a #{reflection.class} for uniqueness scope."
            end

            case
            when reflection&.polymorphic?
              [:"#{part}_type", :"#{part}_id"]
            when reflection
              :"#{part}_id"
            else
              part
            end
          end

          validates :position,
            presence: true,
            uniqueness: {
              scope:     uniqueness_scope,
              allow_nil: true
            },
            numericality: {
              allow_nil:    true,
              only_integer: true,
              greater_than: 0
            }
        end
      end
    end
  end
end
