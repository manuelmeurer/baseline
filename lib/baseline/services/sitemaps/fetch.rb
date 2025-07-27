# frozen_string_literal: true

module Baseline
  module Sitemaps
    class Fetch < ApplicationService
      def call
        Helpers
          .cache_key(::Current.namespace)
          .then {
            Rails.cache.read _1
          }
      end
    end
  end
end
