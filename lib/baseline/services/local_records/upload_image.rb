# frozen_string_literal: true

module Baseline
  module LocalRecords
    class UploadImage < ApplicationService
      def call(local_record, pathname)
        tags = [
          Rails.application.class.module_parent_name.downcase,
          "#{Rails.application.class.module_parent_name.downcase}-#{local_record.class.to_s.underscore.dasherize}"
        ]
        Cloudinary::Uploader.upload(
          pathname,
          resource_type: "auto",
          tags:
        ).fetch_values("public_id", "format")
          .join(".")
      end
    end
  end
end
