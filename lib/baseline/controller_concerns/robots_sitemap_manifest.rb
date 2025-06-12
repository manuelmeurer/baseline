# frozen_string_literal: true

module Baseline
  module RobotsSitemapManifest
    extend ActiveSupport::Concern

    methods = %w[
      robots
      sitemap
      manifest
    ]
    check_unauth_method = :"_#{methods.join("_")}_check_unauth"

    # This is a bit hacky... we need to allow unauthenticated access to some actions,
    # but we can't just say `allow_unauthenticated_access only: methods` since the Authentication
    # concern might not be included yet. This is why we do it in a before_action, which is invoked
    # on every request, and make sure it only calls `allow_unauthenticated_access` once, and if the
    # first request is for one of the actions, redirect immediately so that the authentication
    # is actually skipped on the second request.
    included do
      mattr_accessor check_unauth_method

      before_action only: :manifest do
        unless params[:format] == "json"
          redirect_to url_for(format: :json)
        end
      end

      before_action prepend: true do
        next if self.class.public_send(check_unauth_method)

        # We need to find the class that has included the Authentication concern,
        # it might be a superclass of the current class.
        self
          .class
          .ancestors
          .select { _1.respond_to? :allow_unauthenticated_access }
          .last
          .try(:allow_unauthenticated_access, only: methods)

        self.class.public_send "#{check_unauth_method}=", true

        if action_name.in?(methods)
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

    def manifest
      expires_soon
      render "/manifest"
    end

    private

      def url_for_sitemap
        suppress NoMethodError do
          url_for [::Current.namespace, :sitemap, only_path: false]
        end
      end
  end
end
