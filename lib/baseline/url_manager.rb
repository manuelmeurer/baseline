# frozen_string_literal: true

module Baseline
  class URLManager
    class << self
      def domains = const_get(:DOMAINS).values

      def route_constraints(namespace)
        if Rails.env.production? && domain = const_get(:DOMAINS)[namespace]
          { host: domain }
        else
          {
            subdomain: const_get(:SUBDOMAINS).fetch(namespace, namespace.to_s),
            domain:    Rails.application.env_credentials.host!
          }
        end
      end
    end
  end
end
