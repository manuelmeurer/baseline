# frozen_string_literal: true

module Baseline
  class GenerateAddToCalendarData < ApplicationService
    def call(record, user = ::Current.user)
      {
        google:  "Google",
        outlook: "Outlook.com",
        yahoo:   "Yahoo",
        ics:     "Apple/Outlook (ICS)"
      }.map do |calendar_type, label|
        url = url_for([
          :api,
          :calendar,
          calendar_type:,
          user_id:   user&.signed_id || 0,
          record_id: record.to_sgid
        ])
        image_url = ApplicationController.helpers.image_url("baseline/add_to_calendar/#{calendar_type}.png")

        [
          calendar_type,
          {
            label:,
            url:,
            image_url:
          }
        ]
      end.to_h
    end
  end
end
