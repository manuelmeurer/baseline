# frozen_string_literal: true

module Baseline
  class ClearCloudflareCache < ApplicationService
    def call(*resources)
      urls = resources
        .map do |resource|
          resource.if(Hash) {
            unless resource.size == 1
              raise "Hash must have exactly one key, but has: #{resource.keys}"
            end
            resource.keys.first.constantize.new(resource.values.first)
          }
        end
        .flat_map { url_parts _1 }
        .uniq
        .map { url_for _1 }

      Baseline::External::Cloudflare.purge_cache urls:
    end
  end
end
