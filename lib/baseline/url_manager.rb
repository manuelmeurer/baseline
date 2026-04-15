# frozen_string_literal: true

module Baseline
  class URLManager
    NAMESPACE_DOMAINS = {}

    class << self
      def domains = const_get(:NAMESPACE_DOMAINS).values.flatten

      def internal_host_regex
        %r{
          #{URLFormatValidator.regex}
          (\w+\.)?
          #{Rails.application.env_credentials.host!}
        }ix.freeze
      end

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

      # Returns options with an explicit :host key so redirects work even when
      # the request originates from an IP address (e.g. 127.0.0.1), where Rails
      # cannot decompose the hostname into domain/subdomain parts.
      # An empty subdomain is collapsed so that e.g. "" + "m4l.localhost"
      # becomes host: "m4l.localhost" rather than host: ".m4l.localhost".
      def url_options(namespace)
        route_constraints = route_constraints(namespace)
        if subdomain = route_constraints.delete(:subdomain)
          unless domain = route_constraints.delete(:domain)
            raise "Expected domain if subdomain exists."
          end
          route_constraints[:host] = [subdomain, domain].compact_blank.join(".")
        end
        route_constraints
      end
    end
  end
end
