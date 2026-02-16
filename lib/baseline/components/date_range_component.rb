# frozen_string_literal: true

module Baseline
  class DateRangeComponent < ApplicationComponent
    def initialize(start_date:, end_date:, format: :long)
      @start_date, @end_date, @format =
        start_date, end_date, format
    end

    def call
      start_date, end_date = [@start_date, @end_date].map { parse_date _1 }

      return if start_date.nil? || end_date.nil?

      if same_day?(start_date, end_date)
        format_date(start_date)
      elsif same_month?(start_date, end_date)
        format_same_month(start_date, end_date)
      elsif same_year?(start_date, end_date)
        "#{format_date(start_date, skip_year: true)}#{separator}#{format_date(end_date)}"
      else
        "#{format_date(start_date)}#{separator}#{format_date(end_date)}"
      end
    end

    private

      def parse_date(date)
        case date
        when nil                             then nil
        when Date, Time, DateTime            then date
        when -> { _1.respond_to?(:to_date) } then date.to_date
        else Date.parse(date.to_s)
        end
      end

      def german? = I18n.locale.to_s.start_with?("de")

      def separator = german? ? " – " : "–"

      def same_day?(a, b)   = a.year == b.year && a.month == b.month && a.day == b.day
      def same_month?(a, b) = a.year == b.year && a.month == b.month
      def same_year?(a, b)  = a.year == b.year

      def month_name(date)
        key = @format == :short ? :abbr_month_names : :month_names
        I18n.t(key, scope: :date).fetch(date.month)
      end

      def format_date(date, skip_year: false)
        if german?
          "#{date.day}. #{month_name(date)}#{" #{date.year}" unless skip_year}"
        else
          "#{month_name(date)} #{date.day}#{", #{date.year}" unless skip_year}"
        end
      end

      def format_same_month(start_date, end_date)
        if german?
          "#{start_date.day}.–#{end_date.day}. #{month_name(start_date)} #{end_date.year}"
        else
          "#{month_name(start_date)} #{start_date.day}–#{end_date.day}, #{end_date.year}"
        end
      end
  end
end
