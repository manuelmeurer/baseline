# frozen_string_literal: true

module Baseline
  module Sitemaps
    class GenerateAll < ApplicationService
      def call
        SitemapGenerator::Sitemap.compress = false
        SitemapGenerator::Sitemap.adapter  = self

        call_all_private_methods_without_args
      end

      # This method is called by SitemapGenerator when a new sitemap was generated.
      def write(location, data)
        location
          .filename
          .delete_suffix(".xml")
          .then {
            Rails.cache.write \
              Helpers.cache_key(_1),
              data
          }
      end
    end
  end
end
