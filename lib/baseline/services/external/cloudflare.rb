# frozen_string_literal: true

require "addressable"

module Baseline
  module External
    class Cloudflare < Base
      BASE_URL = "https://api.cloudflare.com".freeze

      add_action :r2_url do |bucket = nil, **query_values|
        Addressable::URI.new(
          scheme:       "https",
          host:         "#{Rails.application.env_credentials.cloudflare.account_id!}.r2.cloudflarestorage.com",
          path:         bucket,
          query_values: query_values.presence
        ).to_s
      end

      add_action :purge_cache do |urls: nil, everything: false|
        if urls.present? && everything
          raise Error, "urls and everything cannot both be supplied."
        end

        path = "client/v4/zones/#{Rails.application.env_credentials.cloudflare.zone_identifier!}/purge_cache"
        params = urls.present? ?
          { files: Array(urls) } :
          { purge_everything: true }
        response = request(:post, path, json: params)

        unless response[:success]
          raise Error, "Unsuccessful response: #{response}"
        end
      end

      private

        def request_headers
          {
            "X-Auth-Email": Rails.application.env_credentials.cloudflare.email!,
            "X-Auth-Key":   Rails.application.env_credentials.cloudflare.api_key!
          }
        end
    end
  end
end
