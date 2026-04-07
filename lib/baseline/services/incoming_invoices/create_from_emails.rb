# frozen_string_literal: true

module Baseline
  module IncomingInvoices
    class CreateFromEmails < ApplicationService
      MAX_ATTACHMENT_SIZE_MB = 20.freeze
      PDF_SUFFIX_REGEX       = /\.pdf\z/i.freeze

      def call
        check_uniqueness

        track_last_run do |last_run_at = 1.week.ago|
          query = {
            to:    email,
            after: last_run_at.to_date
          }
          Emails::Find
            .call(query)
            .each {
              process _1
            }
        end
      end

      private

        memo_wise def gmail = External::Google::Oauth::Service.new(:gmail)

        def process(email)
          task_identifier = [
            :invoice_email,
            email.id
          ].join("_")

          return if Task.exists?(identifier: task_identifier)

          attachment_data = email.find_attachment_data

          case
          when attachment_data.empty?
            unless allow_emails_without_attachments.include?(email.from)
              Tasks::Create.call \
                title:      "Invoice Email ohne Anhang",
                identifier: task_identifier,
                details:    email.url,
                priority:   :low
            end
            return
          when attachment_data.values.none?(PDF_SUFFIX_REGEX)
            Tasks::Create.call \
              title:      "Invoice Email ohne PDF Anhang",
              identifier: task_identifier,
              details:    email.url
            return
          end

          attachment_data.each do |attachment_id, filename|
            clean_filename = filename.tr(":", "_")

            next unless
              PDF_SUFFIX_REGEX.match?(filename) &&
              IncomingInvoice.with_email(email).none? {
                _1.pdf_file.file.filename.to_s == clean_filename
              }

            attachment = gmail.get_user_message_attachment(
              "me",
              email.id,
              attachment_id
            )

            if attachment.size > 20.megabytes
              task_details = <<~DETAILS.chomp
                Email ID: #{email.id}
                Filename: #{filename}
                Size: #{attachment.size}
                URL: #{email.url}
              DETAILS

              Tasks::Create.call \
                title:      "Invoice Email mit zu großem Anhang",
                identifier: task_identifier,
                details:    task_details

              # Don't just exit `each` block but return from the method.
              return
            end

            pdf_file = PDFFile.create!(
              title: "Invoice",
              file:  { io: StringIO.new(attachment.data), filename: clean_filename }
            )

            IncomingInvoice.create!(
              email:,
              pdf_file:,
              **generate_incoming_email_params(email)
            )._do_process(_async: true)
          end
        end

        def allow_emails_without_attachments  = []
        def generate_incoming_email_params(*) = {}
    end
  end
end
