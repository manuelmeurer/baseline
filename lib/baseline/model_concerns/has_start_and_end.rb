# frozen_string_literal: true

module Baseline
  module HasStartAndEnd
    def self.[](
      start_attribute = :start_date,
      end_attribute   = :end_date,
      type:                nil,
      prefix:              nil,
      covering_if_undated: false)

      Module.new do
        extend ActiveSupport::Concern

        included do
          prefixed = -> { [prefix, _1].compact.join("_").if(_1.is_a?(Symbol), &:to_sym) }
          type ||=
            schema_columns
              .fetch_values(start_attribute, end_attribute)
              .map { _1.fetch :type }
              .uniq
              .sole

          validates end_attribute,
            comparison: {
              greater_than_or_equal_to: start_attribute,
              if:                       start_attribute,
              allow_nil:                true
            }

          if self < ActiveRecord::Base
            scope prefixed.call(:upcoming), -> {
              where(start_attribute => (type == :date ? Date.tomorrow : Time.current)..)
            }
            scope prefixed.call(:past), -> {
              where(end_attribute => ..(type == :date ? Date.yesterday : Time.current))
            }
            scope prefixed.call(:current), -> {
              public_send(prefixed.call(:covering), (type == :date ? Date : Time).current)
            }
            scope prefixed.call(:starting_today), -> {
              started_between(*Date.today.all_day.minmax)
            }
            scope prefixed.call(:covering), ->(_start, _end = _start) {
              {
                start_attribute => .._start,
                end_attribute   => _end..
              }.map {
                where(_1 => nil).or(where(_1 => _2))
              }.unless(covering_if_undated) {
                _1.unshift \
                  where.not(start_attribute => nil, end_attribute => nil)
              }.inject(:merge)
            }
          end

          undated_method_name = prefixed.call(:undated?)

          define_method undated_method_name do
            !public_send(start_attribute) &&
              !public_send(end_attribute)
          end

          define_method prefixed.call(:upcoming?) do
            return nil unless start_value = public_send(start_attribute)

            type == :date ?
              start_value >= Date.tomorrow :
              start_value >= Time.current
          end

          define_method prefixed.call(:past?) do
            return nil unless end_value = public_send(end_attribute)

            type == :date ?
              end_value <= Date.yesterday :
              end_value <= Time.current
          end

          define_method prefixed.call(:current?) do
            return nil if !covering_if_undated && public_send(undated_method_name)

            public_send(start_attribute).then { _1.nil? || _1 <= (type == :date ? Date : Time).current } &&
              public_send(end_attribute).then { _1.nil? || _1 >= (type == :date ? Date : Time).current }
          end
        end
      end
    end

    def self.included(base)
      base.include self[]
    end
  end
end
