# frozen_string_literal: true

module Baseline
  module GoogleDrive
    class SyncToLexoffice < ApplicationService
      ATTRIBUTES = %i[id name modified_time].freeze

      mattr_accessor :folder_id

      def call
        drive = Baseline::External::Google::Oauth::Service.new(:drive, AdminUser.manuel)
        files = drive
          .list_files(
            q:      "parents in '#{folder_id}' and trashed = false",
            fields: ATTRIBUTES.join(",").then { "files(#{_1})" }
          ).files
        valid_files, invalid_files = files.partition {
          File
            .extname(_1.name)
            .downcase
            .in?(%w[.pdf .jpg .jpeg .png])
        }

        if invalid_files.any?
          task_identifier = [
            self.class,
            :invalid_files
          ].join("_")

          unless Task.exists?(identifier: task_identifier)
            Tasks::Create.call \
              title:       "Eine oder mehrere Dateien können nicht zu Lexoffice hochgeladen werden.",
              details:     invalid_files.map(&:name).join("\n"),
              identifier:  task_identifier
          end
        end

        valid_files.each do |file|
          Helpers.download_file(file, drive:).then {
            Baseline::External::Lexoffice.create_file _1
          }
          drive.update_file(file.id, file.class.new(trashed: true))
        end
      end
    end
  end
end
