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
        unless params[:format] == "text"
          redirect_to url_for(format: :text)
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

    def manifest
      id   = Rails.application.class.module_parent_name.underscore
      name = id.titleize

      json = manifest_overrides.reverse_merge(
        id:,
        name:,
        icons: [
          {
            src:   view_context.asset_path("icons/icon-192.png"),
            type:  "image/png",
            sizes: "192x192"
          }, {
            src:   view_context.asset_path("icons/icon-512.png"),
            type:  "image/png",
            sizes: "512x512"
          }, {
            src:     view_context.asset_path("icons/icon-mask.png"),
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

    private

      def manifest_overrides = {}
      def allow_robots?      = false
      def render_manifest?   = false
  end
end
