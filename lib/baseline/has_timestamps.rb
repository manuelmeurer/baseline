# frozen_string_literal: true

module Baseline
  module HasTimestamps
    def self.[](*attributes)
      Module.new do
        extend ActiveSupport::Concern

        attributes_and_verbs = attributes.index_with { _1.to_s.sub(/_(at|on|until)\z/, "") }

        included do
          attributes_and_verbs.each do |attribute, verb|
            attribute_with_table_name = "#{table_name}.#{attribute}"

            # If we are using PostgreSQL and the column is a date,
            # we need to cast it to a timestamp, so that comparisons with Time objects work as expected.
            if connection.adapter_name == "PostgreSQL" && columns_hash.fetch(attribute.to_s).type == :date
              attribute_with_table_name << "::timestamp"
            end

            scope verb,        -> { where.not(attribute_with_table_name => nil) }
            scope "un#{verb}", -> { where(attribute_with_table_name => nil) }

            scope "#{verb}_between", ->(start_time, end_time) {
              if start_time >= end_time
                raise "Start time must be before end time."
              end
              where(attribute_with_table_name => start_time..end_time)
            }

            { before: %w(< >), after: %w(> <) }.each do |before_or_after, (operator, unoperator)|
              {
                "#{verb}_#{before_or_after}"   => -> { "#{attribute_with_table_name} #{operator} #{_1}" },
                "un#{verb}_#{before_or_after}" => -> { "(#{attribute_with_table_name} IS NULL) OR (#{attribute_with_table_name} #{unoperator} #{_1})" }
              }.each do |scope_name, sql|
                scope scope_name, ->(time = Time.current) {
                  placeholder, params =
                    time.is_a?(Time) || time.is_a?(Date) ?
                    ["?", [time]] :
                    [time, []]
                  where(sql.call(placeholder), *params)
                }
              end
            end
          end
        end

        class_methods do
          %i(scopes methods).each do |type|
            define_method "timestamp_#{type}" do |*attributes|
              Array(attributes).flat_map do |attribute|
                unless verb = attributes_and_verbs[attribute]
                  raise "#{attribute} is not a valid timestamp method."
                end

                if type == :scopes
                  [
                    verb.to_sym,
                    :"un#{verb}",
                    :"#{verb}_before",
                    :"#{verb}_after",
                    :"#{verb}_between",
                    :"un#{verb}_before",
                    :"un#{verb}_after"
                  ]
                else
                  [
                    attribute.to_sym,
                    :"#{verb}?",
                    :"un#{verb}?",
                    :"#{verb}!",
                    :"un#{verb}!",
                    :"#{verb}_before?",
                    :"#{verb}_after?",
                    :"#{verb}_between?"
                  ]
                end
              end
            end
          end
        end

        attributes_and_verbs.each do |attribute, verb|
          define_method "#{attribute}=" do |value|
            case value
            when String
              value = Time.zone.parse(value)
            when Hash
              if value = value.compact_blank.presence
                new_value = public_send(attribute) || Time.current
                value.each do |unit, amount|
                  changes = case unit.to_sym
                            when :date
                              if amount.is_a?(String)
                                amount = Time.zone.parse(amount)
                              end
                              %i(year month day).index_with { amount.public_send _1 }
                            when :time
                              if amount.is_a?(String)
                                amount = Time.zone.parse(amount)
                              end
                              %i(hour min sec).index_with { amount.public_send _1 }
                            else
                              change_unit = {
                                hours:   :hour,
                                minutes: :min,
                                seconds: :sec
                              }.fetch(unit.to_sym) { unit.to_sym }
                              { change_unit => amount.to_i }
                            end
                  new_value = new_value.change(changes)
                end
                value = new_value
              end
            end

            write_attribute attribute, value
          end

          define_method "#{verb}?" do
            !!public_send(attribute)
          end
          unless verb.to_s == attribute.to_s # Avoid circular method calls.
            alias_method verb, "#{verb}?"
          end

          define_method "un#{verb}?" do
            !public_send("#{verb}?")
          end
          alias_method "un#{verb}", "un#{verb}?"

          define_method "#{verb}_between?" do |start_time, end_time|
            if start_time >= end_time
              raise "Start time must be before end time."
            end
            public_send("#{verb}?") && (start_time..end_time).cover?(public_send(attribute))
          end

          { before: %w(before? after?), after: %w(after? before?) }.each do |before_or_after, (method, unmethod)|
            define_method "#{verb}_#{before_or_after}?" do |time = Time.current|
              public_send("#{verb}?") && public_send(attribute).public_send(method, time)
            end
            define_method "un#{verb}_#{before_or_after}?" do |time = Time.current|
              public_send("un#{verb}?") || public_send(attribute).public_send(unmethod, time)
            end
          end

          define_method "#{verb}!" do |time: Time.current, overwrite: true|
            if overwrite || public_send("un#{verb}?")
              update! attribute => time
            end
          end

          define_method "un#{verb}!" do
            public_send "#{verb}!", time: nil
          end

          unless verb.to_s == attribute.to_s # Avoid circular method calls.
            define_method "#{verb}=" do |value|
              if ActiveRecord::Type::Boolean.new.cast(value)
                unless public_send("#{verb}?")
                  public_send "#{attribute}=", Time.current
                end
              else
                public_send "#{attribute}=", nil
              end
            end
          end
        end
      end
    end
  end
end
