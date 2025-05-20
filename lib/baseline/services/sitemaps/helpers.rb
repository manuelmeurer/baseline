# frozen_string_literal: true

module Baseline
  module Sitemaps
    module Helpers
      private def cache_key(namespace)
        [
          :sitemap,
          namespace
        ].join(":")
      end
    end
  end
end
