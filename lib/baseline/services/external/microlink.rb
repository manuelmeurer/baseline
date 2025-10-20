# frozen_string_literal: true

module Baseline
  module External
    class Microlink < ::External::Base
      BASE_URL = "https://api.microlink.io/".freeze

      add_action :get_metadata, run_unless_prod: true do |url, cache: false|
        return do_get(url) unless cache

        cache_key = [
          :microlink,
          Digest::MD5.hexdigest(url)
        ]
        params = if cache.is_a?(ActiveSupport::Duration)
          { expires_in: cache }
        end

        Rails.cache.fetch(cache_key, **params) do
          do_get(url)
        end
      end

      private

        def do_get(url)
          response = request(:get, "", params: { url: })
          unless response[:status] == "success"
            ReportError.call "how to handle non-sucess?",
              response:
          end
          response.fetch(:data)
        end
    end
  end
end
