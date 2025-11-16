# frozen_string_literal: true

module Baseline
  module HasStartAndEnd
    def self.[](start_attribute, end_attribute)
      Module.new do
        extend ActiveSupport::Concern

        included do
          validates end_attribute,
            comparison: {
              greater_than_or_equal_to: start_attribute,
              if:                       start_attribute,
              allow_nil:                true
            }

          type =
            schema_columns
              .fetch_values(start_attribute, end_attribute)
              .map { _1.fetch :type }
              .uniq
              .sole

          scope :upcoming,       -> { where(start_attribute => (type == :date ? Date.tomorrow : Time.current)..) }
          scope :past,           -> { where(end_attribute => ..(type == :date ? Date.yesterday : Time.current)) }
          scope :current,        -> { covering((type == :date ? Date : Time).current) }
          scope :starting_today, -> { started_between(*Date.today.all_day.minmax) }

          scope :covering,  ->(_start, _end = _start) {
            {
              start_attribute => .._start,
              end_attribute   => _end..
            }.map {
              where(_1 => nil).or(where(_1 => _2))
            }.inject(:merge)
          }

          define_method :upcoming? do
            return nil unless start_value = public_send(start_attribute)
            type == :date ?
              start_value >= Date.tomorrow :
              start_value >= Time.current
          end

          define_method :past? do
            return nil unless end_value = public_send(end_attribute)
            type == :date ?
              end_value <= Date.yesterday :
              end_value <= Time.current
          end

          define_method :current? do
            public_send(start_attribute).then { _1.nil? || _1 <= (type == :date ? Date : Time).current } &&
              public_send(end_attribute).then { _1.nil? || _1 >= (type == :date ? Date : Time).current }
          end
        end
      end
    end

    def self.included(base)
      base.include self[:start_date, :end_date]
    end
  end
end
