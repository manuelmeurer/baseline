# frozen_string_literal: true

module Baseline
  class MigrateBlobToCloudflare < ApplicationService
    def call(blob)
      return unless blob.service_name == "cloudinary"

      check_uniqueness on_error: :return

      service = ActiveStorage::Blob.services.fetch(:cloudflare)

      unless service.exist?(blob.key)
        blob.open do |file|
          service.upload \
            blob.key,
            file,
            checksum:     blob.checksum,
            content_type: blob.content_type,
            filename:     blob.filename
        end
      end

      blob.update!(service_name: "cloudflare")
    end
  end
end
