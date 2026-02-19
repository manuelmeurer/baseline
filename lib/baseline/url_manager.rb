# frozen_string_literal: true

module Baseline
  class URLManager
    class << self
      def domains = const_get(:NAMESPACE_DOMAINS).values.flatten

      def route_constraints(namespace)
        if Rails.env.production? && domain = const_get(:NAMESPACE_DOMAINS)[namespace]
          { host: domain }
        else
          {
            subdomain: const_get(:NAMESPACE_SUBDOMAINS).fetch(namespace, namespace.to_s),
            domain:    Rails.application.env_credentials.host!
          }
        end
      end

      def url_options(namespace)
        route_constraints = route_constraints(namespace)
        if subdomain = route_constraints.delete(:subdomain)
          unless domain = route_constraints.delete(:domain)
            raise "Expected domain if subdomain exists."
          end
          route_constraints[:host] = [subdomain, domain].join(".")
        end
        route_constraints
      end
    end
  end
end
