# frozen_string_literal: true

module Baseline
  module EssentialsControllable
    extend ActiveSupport::Concern

    included do
      try :allow_unauthenticated_access

      before_action only: :manifest do
        case
        when !render_manifest?
          head :not_found
        when params[:format] != "json"
          redirect_to url_for(format: :json)
        end
      end

      before_action only: :robots do
        unless params[:format] == "txt"
          redirect_to url_for(format: :text)
        end
      end

      before_action only: :sitemap do
        unless params[:format] == "xml"
          redirect_to url_for(format: :xml)
        end
      end

      before_action only: :favicon do
        case
        when !render_favicon?
          head :not_found
        when params[:format] != "ico"
          redirect_to url_for(format: :ico)
        end
      end
    end

    def robots
      response =
        if allow_robots?
          {
            "User-agent": "*",
            "Allow":      "/",
            "Sitemap":    url_for([::Current.namespace, :sitemap, only_path: false])
          }
        else
          {
            "User-agent": "*",
            "Disallow":   "/"
          }
        end.map { [_1, _2].join(": ") }.join("\n")

      try :expires_soon
      render plain: response
    end

    def sitemap
      sitemap = Sitemaps::Fetch.call.presence

      unless allow_robots? && sitemap
        if sitemap
          ReportError.call "Robots are not allowed to crawl but a sitemap is present."
        end
        head :not_found
        return
      end

      try :expires_soon
      render xml: sitemap
    end

    def favicon
      asset_path = namespaced_or_default_asset("icons/favicon.ico").path
      send_file asset_path, disposition: "inline"
    end

    def manifest
      asset_paths = [192, 512, :mask].index_with do |suffix|
        namespaced_or_default_asset("icons/icon-#{suffix}.png").url
      end

      json = manifest_overrides.reverse_merge(
        name: Rails.application.class.module_parent_name.underscore.titleize,
        icons: [
          {
            src:   asset_paths.fetch(192),
            type:  "image/png",
            sizes: "192x192"
          }, {
            src:   asset_paths.fetch(512),
            type:  "image/png",
            sizes: "512x512"
          }, {
            src:     asset_paths.fetch(:mask),
            type:    "image/png",
            sizes:   "512x512",
            purpose: "maskable"
          }
        ],
        start_url: "/",
        display:   "standalone",
        scope:     "/"
      )

      try :expires_soon
      render json: JSON.pretty_generate(json)
    end

    def render_manifest? = false
    def render_favicon?  = true

    private

      def manifest_overrides = {}
      def allow_robots?      = false
  end
end
