# frozen_string_literal: true

module Baseline
  module External
    class Meta < ::External::Base
      BASE_URL = "https://graph.facebook.com/v25.0".freeze

      add_action :send_event do |name, **data|
        event = {
          event_name:       name,
          event_time:       data[:event_time] || Time.current.to_i,
          event_id:         data[:event_id],
          action_source:    data[:action_source] || "website",
          event_source_url: data[:url],
          user_data:        data[:user_data]&.transform_values { hash_value(_1) },
          custom_data:      data[:custom_data]
        }.compact

        request :post,
          "#{credentials.pixel_id!}/events",
          json: { data: [event] }
      end

      add_action :ping do
        request :get, "me"
      end

      add_action :get_leadgen do |leadgen_id|
        request :get,
          leadgen_id,
          params: {
            access_token: credentials.page_access_token!,
            fields:       "id,created_time,ad_id,form_id,field_data"
          }
      end

      private

        def request_auth = "Bearer #{credentials.capi_access_token!}"
        def credentials  = Rails.application.env_credentials.meta

        def hash_value(value)
          return value if value.nil? || value.match?(/\A[a-f0-9]{64}\z/)
          Digest::SHA256.hexdigest(value.to_s.strip.downcase)
        end
    end
  end
end
