# frozen_string_literal: true

module Baseline
  module External
    class HTMLCSSToImage < ::External::Base
      include Cooldowner

      BASE_URL  = "https://hcti.io/v1".freeze
      DUMMY_URL = "https://weirdspace.info/RuneAndreasson/Graphics/Pellefant.gif".freeze

      Cooldown = Class.new(Error)

      add_action :generate_image_url, return_unless_prod: DUMMY_URL do |**params|
        raise Cooldown if cooldown?

        params = params.reverse_merge(
          device_scale:       2,
          ms_delay:       1_000,
          viewport_width:   600
        )
        params[:viewport_height] ||= params[:viewport_width] * 3

        begin
          response = request(:post, "image", json: params)
        rescue ExternalService::RequestError => error
          if error.status.too_many_requests?
            cooldown!(1.minute)
            raise Cooldown
          else
            raise error
          end
        else
          response.fetch(:url)
        end
      end

      add_action :generate_embed_image_url, return_unless_prod: DUMMY_URL do |url|
        timestamp, embed_image_url = do_generate_embed_image_url(url)

        if Time.parse(timestamp) < 1.day.ago
          begin
            new_embed_image_url = do_generate_embed_image_url(url, force: true).last
          rescue Cooldown
          else
            embed_image_url = new_embed_image_url
          end
        end

        embed_image_url
      end

      private

        def do_generate_embed_image_url(url, force: false)
          cache_key = [
            :hcti_embed_image,
            ActiveSupport::Digest.hexdigest(url)
          ].join(":")

          Rails.cache.fetch(cache_key, force:) do
            html      = tag.html { tag.body { component(:preview_card, url) } }
            image_url = call(:generate_image_url, html:, selector: "body > a")

            [
              Time.current.iso8601,
              image_url
            ]
          end
        end

        def request_basic_auth
          Rails.application.env_credentials.hcti!.then {
            {
              user: _1.user_id!,
              pass: _1.api_key!
            }
          }
        end

        def request_retry_reasons = super.without(:too_many_requests)
    end
  end
end
