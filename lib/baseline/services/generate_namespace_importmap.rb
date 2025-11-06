# frozen_string_literal: true

module Baseline
  class GenerateNamespaceImportmap < ApplicationService
    def call
      if Rails.env.development?
        Rails.configuration.importmaps = nil
      end

      Rails.configuration.importmaps ||= generate_importmaps

      Rails.configuration.importmaps.fetch(::Current.namespace)
    end

    private

      def generate_importmaps
        Rails
          .configuration
          .app_stimulus_namespaces
          .transform_values do |entrypoints|

          Rails.application.importmap.clone.tap do |importmap|
            dirs = importmap.directories.select {
              _1.exclude?("/controllers/") ||
                _1.match?(%r{/controllers/(#{entrypoints.join("|")})\b})
            }
            importmap.instance_variable_set \
              "@directories",
              dirs
            importmap.instance_variable_set \
              "@cache",
              {}
          end
        end
      end
  end
end
