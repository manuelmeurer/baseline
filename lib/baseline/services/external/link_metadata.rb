# frozen_string_literal: true

module Baseline
  module External
    class LinkMetadata < ::External::Base
      BASE_URL = "https://api.linkmetadata.com/v1".freeze

      add_action :get_metadata, run_unless_prod: true do |url, cache: false|
        if cache
          cache_key = [
            :link_metadata,
            Digest::MD5.hexdigest(url)
          ]
          params = if cache.is_a?(ActiveSupport::Duration)
            { expires_in: cache }
          end

          Rails.cache.fetch(cache_key, **params) do
            do_get(url)
          end
        else
          do_get(url)
        end
      end

      private

        def do_get(url)
          request :get, "metadata", params: { url: }
        end
    end
  end
end
