# frozen_string_literal: true

module Baseline
  class Toucher < ApplicationService
    CACHE_KEY = :toucher

    def add(resource)
      read_cache do |value|
        Set.new([*value, resource.to_gid.to_s])
      end
    end

    def call
      gids = nil
      read_cache do |value|
        gids = value
        []
      end

      return unless gids.present?

      gids.each do |gid|
        next unless resource = GlobalID.find(gid)

        resource
          .class
          .touch_async_associations
          .each do |association_name|

          resource
            .public_send(association_name)
            .then { Array _1 }
            .each {
              _1.touch time: resource.updated_at
            }
        end
      end
    end

    private

      def read_cache(&block)
        SolidCache::Entry.lock_and_write CACHE_KEY, &block
      end
  end
end
