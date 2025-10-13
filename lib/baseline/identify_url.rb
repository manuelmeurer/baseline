# frozen_string_literal: true

module Baseline
  class IdentifyURL < ApplicationService
    Result = Data.define(:icon, :name, :icon_and_name)

    def call(url, square_icon: false)
      require "addressable/uri"

      uri = Addressable::URI.parse(url)
      url = uri.normalize.to_s

      cache_key = [
        :identify_url,
        ActiveSupport::Digest.hexdigest(url),
        square_icon
      ].join(":")

      Rails.cache.fetch cache_key do
        case host = uri.host.delete_prefix("www.").downcase
        when "youtube.com"
          icon = component(:icon, "#{"square-" if square_icon}youtube", version: :brands)
          name = "YouTube"
        when "meetup.com"
          icon = component(:icon, "meetup", version: :brands)
          name = "Meetup.com"
        when "lu.ma"
          icon = component(:icon, "star-christmas", version: :solid)
          name = "Luma"
        when /\A([a-z]{2}\.)?linkedin\.com/
          icon = component(:icon, "linkedin", version: :brands)
          name = "LinkedIn"
        when "bsky.app"
          icon = component(:icon, "#{"square-" if square_icon}bluesky", version: :brands)
          name = "Bluesky"
        when /\Amastodon\./
          icon = component(:icon, "mastodon", version: :brands)
          name = "Mastodon"
        when "twitter.com", "x.com"
          icon = component(:icon, "#{"square-" if square_icon}x-twitter", version: :brands)
          name = "X/Twitter"
        when "facebook.com"
          icon = component(:icon, "#{"square-" if square_icon}facebook", version: :brands)
          name = "Facebook"
        when "instagram.com"
          icon = component(:icon, "#{"square-" if square_icon}instagram", version: :brands)
          name = "Instagram"
        when "github.com"
          icon = component(:icon, "#{"square-" if square_icon}github", version: :brands)
          name = "GitHub"
        else
          icon = component(:icon, :external)
          name = [
            /\A(eventbrite|crowdcast)\./,
            /\b(zoom)\./ # Zoom uses a host like "us06web.zoom.us"
          ].map { host[_1, 1] }
            .compact
            .first
            &.titleize ||
              host
        end

        Result.new \
          icon:,
          name:,
          icon_and_name: [icon, name].join(" ")
      end
    end
  end
end
