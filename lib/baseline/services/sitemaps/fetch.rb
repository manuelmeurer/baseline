# frozen_string_literal: true

module Baseline
  module Sitemaps
    class Fetch < ApplicationService
      include Helpers

      def call(namespace)
        Rails.cache.read \
          cache_key(namespace)
      end
    end
  end
end
