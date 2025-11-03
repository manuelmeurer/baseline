# frozen_string_literal: true

module Baseline
  module External
    class LogoDev < ::External::Base
      BASE_URL = "https://img.logo.dev"

      add_action :get_url, run_unless_prod: true do |logo_url, **options|
        logo_url_host = Addressable::URI.parse(logo_url).host
        base_uri      = Addressable::URI.parse(BASE_URL)

        Addressable::URI.new(
          scheme:       base_uri.scheme,
          host:         base_uri.host,
          path:         logo_url_host,
          query_values: get_params(options)
        ).to_s
      end

      add_action :get_logo, run_unless_prod: true do |logo_url, **options|
        logo_url_host = Addressable::URI.parse(logo_url).host

        begin
          request :get,
            logo_url_host,
            params: get_params(options)
        rescue Baseline::ExternalService::RequestError => error
          raise error unless error.status == 404
        end
      end

      private

        def get_params(options)
          options.reverse_merge \
            token:    Rails.application.env_credentials.logo_dev_token!,
            retina:   "true",
            format:   "png",
            fallback: 404
        end
    end
  end
end
