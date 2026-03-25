# frozen_string_literal: true

module Baseline
  class GenerateIcal < ApplicationService
    def call(title, records)
      require "tzinfo"
      require "icalendar"
      require "icalendar/tzinfo"

      tzid     = "Europe/Berlin"
      tz       = TZInfo::Timezone.get(tzid)
      timezone = tz.ical_timezone(Time.current)

      calendar = Icalendar::Calendar.new
      calendar.x_wr_calname = title
      calendar.add_timezone(timezone)

      records.each do |record|
        calendar.event do |calendar_event|
          { dtstart: record.started_at, dtend: record.ended_at }.each do |attribute, date_or_time|
            if date_or_time
              klass = Icalendar::Values.const_get(date_or_time.is_a?(Date) ? "Date" : "DateTime")
              calendar_event.public_send "#{attribute}=", klass.new(date_or_time, tzid:)
            end
          end
          calendar_event.uid         = record.identifier
          calendar_event.url         = record.url
          calendar_event.summary     = record.title
          calendar_event.description = record.description
          calendar_event.organizer = Icalendar::Values::CalAddress.new(
            "mailto:#{Rails.application.env_credentials.mail_from!}",
            cn: ApplicationMailer.from_name
          )
          if record.location
            calendar_event.location = record.location
          end
        end
      end

      calendar.publish
      calendar.to_ical
    end
  end
end
