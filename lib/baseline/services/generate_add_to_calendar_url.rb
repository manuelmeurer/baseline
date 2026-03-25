# frozen_string_literal: true

require "addressable/uri"

module Baseline
  class GenerateAddToCalendarURL < ApplicationService
    def call(calendar_type, title:, description:, started_at:, ended_at:, location: nil)
      @title, @description, @started_at, @ended_at, @location =
        title, description, started_at, ended_at, location

      send "generate_#{calendar_type}"
    end

    private

      # https://github.com/InteractionDesignFoundation/add-event-to-calendar-docs/blob/master/services/google.md
      def generate_google
        query_values = {
          action:  "TEMPLATE",
          text:    @title,
          dates:   [@started_at, @ended_at].map { utc_iso8601_time_without_dividers _1 }.join("/"),
          details: @description,
          sf:      true.to_s,
          output:  "xml"
        }
        if @location
          query_values[:location] = @location.to_s
        end
        Addressable::URI.new(
          scheme:       "https",
          host:         "www.google.com",
          path:         "calendar/render",
          query_values:
        ).to_s
      end

      # https://github.com/InteractionDesignFoundation/add-event-to-calendar-docs/blob/master/services/outlook-web.md
      def generate_outlook
        time_query_values = {
          startdt: @started_at,
          enddt:   @ended_at
        }.transform_values { _1.utc.iso8601 }
        query_values = time_query_values.merge(
          path:    "/calendar/action/compose",
          rru:     "addevent",
          subject: @title,
          body:    @description
        )
        if @location
          query_values[:location] = @location.to_s
        end
        Addressable::URI.new(
          scheme:       "https",
          host:         "outlook.live.com",
          path:         "owa",
          query_values:
        ).to_s
      end

      # https://github.com/InteractionDesignFoundation/add-event-to-calendar-docs/blob/master/services/yahoo.md
      def generate_yahoo
        time_query_values = {
          st: @started_at,
          et: @ended_at
        }.transform_values { utc_iso8601_time_without_dividers _1 }
        query_values = time_query_values.merge(
          v:     60,
          title: @title,
          desc:  @description
        )
        if @location
          query_values[:in_loc] = @location.to_s
        end
        Addressable::URI.new(
          scheme:       "https",
          host:         "calendar.yahoo.com",
          query_values:
        ).to_s
      end

      def utc_iso8601_time_without_dividers(time)
        time.utc.iso8601.gsub(/[^0-9TZ]/, "")
      end
  end
end
