# frozen_string_literal: true

module Baseline
  module WebBaseControllable
    extend ActiveSupport::Concern

    included do
      helper :web

      skip_forgery_protection

      after_action do
        if flash.keys.any? || params.key?(:flash)
          expires_now
        else
          request.session_options[:skip] = true
        end
      end
    end

    def html_redirect_to(options = {}, response_options = {})
      if flash.keys.any?
        url = url_for(options)
        if web_url?(url)
          options = Addressable::URI
            .parse(url)
            .tap { _1.query_values = Hash(_1.query_values).merge(flash: nil) }
            .to_s
        end
      end

      super options, response_options
    end

    private def web_url?(url)
      URI(url).host == Rails.application.env_credentials.host!
    end
  end
end
