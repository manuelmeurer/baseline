# frozen_string_literal: true

module Baseline
  module LocalRecords
    class UpsertAll < ApplicationService
      CACHE_KEY = :local_records_created

      def skippable?
        Rails.cache.read(CACHE_KEY) == Rails.configuration.revision
      end

      def call(force: false)
        return if skippable? && !force

        Rails.application.eager_load!

        new_records = []

        LocalRecord
          .descendants
          .each do |klass|

          klass
            .path
            .join("*", "*.md")
            .then { Dir[_1] }
            .reject { _1.include?("/drafts/") }
            .each do |file_path|

              unless match = file_path.match(Baseline::ActsAsLocalRecord::PUBLISHED_PATH_REGEX)
                raise Error, "Invalid file path: #{file_path}"
              end

              year, month, day, slug = match
                .named_captures(symbolize_names: true)
                .fetch_values(:year, :month, :day, :slug)

              published_on = Date.new(year.to_i, month.to_i, day.to_i)

              record = klass
                .where(published_on:, slug:)
                .first_or_initialize {
                  new_records << _1
                }

              record.file = file_path

              if record.changed?
                record.save!
                if defined?(::ClearCloudflareCache)
                  ::ClearCloudflareCache.call_async record
                end
              end
            end
        end

        Rails.cache.write \
          CACHE_KEY,
          Rails.configuration.revision

        new_records
      end
    end
  end
end
