# frozen_string_literal: true

module Baseline
  module Lexoffice
    class DownloadPDF < ApplicationService
      VOUCHER_TYPES = %i[invoice credit_note].freeze

      def call(record, voucher_type)
        if record.lexoffice_id.blank?
          raise Error, "Cannot download PDF without a Lexoffice ID."
        end
        unless voucher_type.in?(VOUCHER_TYPES)
          raise Error, "Unexpected voucher type: #{voucher_type}. Must be one of: #{VOUCHER_TYPES.join(", ")}."
        end

        lexoffice_method = :"get_#{voucher_type}"
        lexoffice_document_method = [
          lexoffice_method,
          :document
        ].join("_")

        file_id =
          Baseline::External::Lexoffice
            .public_send(lexoffice_method, record.lexoffice_id)
            .dig(:files, :documentFileId)
            .presence ||
          Baseline::External::Lexoffice
            .public_send(lexoffice_document_method, record.lexoffice_id)
            .fetch(:documentFileId)
            .presence

        unless file_id
          raise Error, "Cannot find File ID."
        end

        data = Baseline::External::Lexoffice.get_file(file_id)

        filename = [
          record.class.to_s.underscore,
          (record.id if record.persisted?)
        ].compact
          .join("_")

        record.pdf_file&.destroy!
        record.build_pdf_file(
          title: record.class.model_name.human,
          file:  { io: StringIO.new(data), filename: "#{filename}.pdf" }
        ).tap do |pdf_file|
          if record.persisted?
            pdf_file.save!
          end
        end
      end
    end
  end
end
