# frozen_string_literal: true

module Baseline
  module HasEventSchemaData
    def event_schema_data
      location_data = try(:location) ?
        {
          "@type": "Place",
          name:    location.name,
          address: {
            "@type":         "PostalAddress",
            streetAddress:   location.address,
            addressLocality: location.city,
            postalCode:      location.zip,
            addressCountry:  location.country
          }
        } : {
          "@type": "VirtualLocation",
          url:     Rails.application.routes.url_helpers.url_for([:web, self])
        }

      image = if header_images.attached?
        rails_blob_url(header_images.closest_to_aspect_ratio(16.0/9))
      end
      {
        image:,
        "@context":          "http://schema.org",
        "@type":             "Event",
        name:                title,
        description:         description,
        startDate:           started_at.iso8601,
        endDate:             ended_at.to_date.iso8601,
        eventAttendanceMode: "https://schema.org/#{defined?(Meetup) && is_a?(Meetup) ? "Offline" : "Online"}EventAttendanceMode",
        eventStatus:         "https://schema.org/Event#{cancelled? ? "Cancelled" : "Scheduled"}",
        location:            location_data,
        organizer:           ApplicationController.helpers.organization_schema_data(include_context: false)
      }
    end
  end
end
