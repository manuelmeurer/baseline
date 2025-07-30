# frozen_string_literal: true

module Baseline
  module WebBaseControllable
    extend ActiveSupport::Concern

    included do
      helper :web

      skip_forgery_protection

      after_action do
        if flash.keys.any? && response.redirect? && web_url?(response.location)
          Addressable::URI
            .parse(response.location)
            .tap { _1.query_values = Hash(_1.query_values).merge(flash: nil) }
            .then { response.location = _1.to_s }
        end

        if flash.keys.any? || params.key?(:flash)
          expires_now
        else
          request.session_options[:skip] = true
        end
      end
    end

    private def web_url?(url)
      URI(url).host == Rails.application.env_credentials.host!
    end
  end
end
