# frozen_string_literal: true

module Baseline
  module GoogleDrive
    module Helpers
      ATTRIBUTES = %i[id name modified_time].freeze

      extend self

      def download_file(file_or_id, drive: nil)
        drive ||= Baseline::External::Google::Oauth::Service.new(:drive)
        file = file_or_id.if(String) {
          drive.get_file(_1, fields: ATTRIBUTES.join(","))
        }

        ATTRIBUTES.each do |attribute|
          if file.public_send(attribute).blank?
            raise Error, "Expected file to have a #{attribute} but it's blank."
          end
        end

        pathname = Rails.root.join(
          "tmp",
          "google_drive_files",
          "#{file.id}_#{file.modified_time.iso8601}",
          file.name
        )

        unless pathname.exist?
          FileUtils.mkdir_p pathname.dirname
          drive.get_file file.id,
            download_dest: File.open(pathname, "wb")
        end

        File.open(pathname)
      end
    end
  end
end
