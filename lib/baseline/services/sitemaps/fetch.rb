# frozen_string_literal: true

module Baseline
  module Sitemaps
    class Fetch < ApplicationService
      def call(namespace)
        Rails.cache.read \
          Helpers.cache_key(namespace)
      end
    end
  end
end
