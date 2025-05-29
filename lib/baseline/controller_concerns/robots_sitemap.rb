# frozen_string_literal: true

module Baseline
  module RobotsSitemap
    extend ActiveSupport::Concern

    # This is a bit hacky... we need to allow unauthenticated access to the "robots" action,
    # but we can't just say `allow_unauthenticated_access, only: :robots` since the Authentication
    # concern might not be included yet. This is why we do it in a before_action, which is invoked
    # on every request, but make sure to only call `allow_unauthenticated_access` once, and if the
    # first request is for robots, redirect so that the authentication is actually skipped on the
    # second request.
    included do
      mattr_accessor :_robots_sitemap_unauthenticated_access

      before_action prepend: true do
        next if self.class._robots_sitemap_unauthenticated_access

        # We need to find the class that has included the Authentication concern,
        # it might be a superclass of the current class.
        self
          .class
          .ancestors
          .select { _1.respond_to? :allow_unauthenticated_access }
          .last
          .try(:allow_unauthenticated_access, only: %i[robots sitemap])

        self.class._robots_sitemap_unauthenticated_access = true

        if action_name.in?(%w[robots sitemap])
          redirect_to params.permit!
        end
      end
    end

    def robots
      response = {
        allow: <<~ROBOTS.strip,
            User-agent: *
            Allow: /
            #{url_for_sitemap&.then { "Sitemap: #{_1}" }}
          ROBOTS
        disallow: <<~ROBOTS
            User-agent: *
            Disallow: /
          ROBOTS
      }.fetch(params[:id].to_sym)

      render plain: response
    end

    def sitemap
      if sitemap = Sitemaps::Fetch.call(::Current.namespace).presence
        render xml: sitemap
      else
        head :ok
      end
    end

    private

      def url_for_sitemap
        suppress NoMethodError do
          url_for [::Current.namespace, :sitemap, only_path: false]
        end
      end
  end
end
