# frozen_string_literal: true

module Baseline
  module HasDelivery
    def self.[](*types)
      associations      = types.map { :"#{_1}_delivery" }
      association_class = associations.first.to_s.classify.constantize

      Module.new do
        extend ActiveSupport::Concern

        included do
          associations.each do |association|
            has_one association,
              as:         :deliverable,
              inverse_of: :deliverable,
              dependent:  :destroy
            accepts_nested_attributes_for association
          end

          if associations.one?
            validates associations.first, presence: true
          else
            validate do
              if associations.map { public_send _1 }.compact_blank.many? || !delivery
                errors.add :base, message: "must have exactly one of these deliveries: #{types.join(", ")}"
              end
            end
          end

          delegate *association_class.timestamp_methods(:sent_at, :scheduled_at),
            to:        :delivery,
            allow_nil: true

          [
            *association_class.timestamp_scopes(:sent_at, :scheduled_at),
            :rejected,
            :unrejected
          ].each do |scope_name|
            scope scope_name, ->(*args) {
              classes = associations.map do |association|
                association.to_s.classify.constantize
              end

              scopes = classes.inject(nil) do |scope, klass|
                class_scope = klass.public_send(scope_name, *args).persisted
                scope&.or(class_scope) || class_scope
              end

              left_outer_joins(*associations).merge(scopes)
            }
          end
        end

        define_method :delivery do
          associations
            .map { public_send _1 }
            .detect(&:present?)
        end

        define_method :delivery= do |delivery|
          public_send "#{delivery.class.to_s.underscore}=", delivery
        end
      end
    end
  end
end
