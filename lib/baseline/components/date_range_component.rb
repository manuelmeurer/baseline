# frozen_string_literal: true

module Baseline
  class DateRangeComponent < ApplicationComponent
    def initialize(start_date:, end_date:, format: :long)
      @start_date, @end_date, @format =
        start_date, end_date, format
    end

    # Chicago Manual of Style formatting with en dash (–)
    def call
      start_date, end_date = [@start_date, @end_date].map { parse_date _1 }

      return if start_date.nil? || end_date.nil?

      case
      when start_date.year == end_date.year &&
        start_date.month == end_date.month &&
        start_date.day == end_date.day

        format_date(start_date)
      when start_date.year == end_date.year && start_date.month == end_date.month
        # Same month: June 12–13, 2026
        "#{format_date(start_date, skip_year: true)}–#{end_date.day}, #{end_date.year}"
      when start_date.year == end_date.year
        # Different months, same year: June 12–July 13, 2026
        "#{format_date(start_date, skip_year: true)}–#{format_date(end_date)}"
      else
        # Different years: June 12, 2026–July 13, 2027
        "#{format_date(start_date)}–#{format_date(end_date)}"
      end
    end

    private

      def parse_date(date)
        return date if date.is_a?(Date) || date.is_a?(Time) || date.is_a?(DateTime)
        return date.to_date if date.respond_to?(:to_date)

        Date.parse(date.to_s)
      rescue ArgumentError, TypeError
      end

      def format_date(date, skip_year: false)
        month = { short: "%b", long: "%B" }.fetch(@format)
        date.strftime("#{month} %-d#{", %Y" unless skip_year}")
      end
  end
end
