# frozen_string_literal: true

module Baseline
  class ProcessInvoiceEmails < ApplicationService
    MAX_ATTACHMENT_SIZE_MB = 20.freeze
    PDF_SUFFIX_REGEX       = /\.pdf\z/i.freeze
    FORWARDED_FOR_REGEXES  = "[^@\s]+@[^@\s]+?".then { [
      /(from|von):\s+([a-zA-Z@\.\s]{0,50})?\s*<(?<email>#{_1})>/i,
      /<(?<email>#{_1})>\s+wrote:/i
    ] }.freeze

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

        unless from = email.from&.downcase
          raise Error, "Cannot find a sender for email #{email.id}."
        end

        from_admin =
          [from, email].map { _1.split("@").last }.uniq.one? ||
          from == "manuel@meurer.io"

        if from_admin
          from = FORWARDED_FOR_REGEXES
            .map { email.text[_1, :email] }
            .detect(&:present?)
            &.downcase
        end

        attachment_data = email.find_attachment_data

        case
        when attachment_data.empty?
          unless from&.then { allow_emails_without_attachments.include? _1.downcase }
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

        incoming_email_params = generate_incoming_email_params(from)

        attachment_data.each do |attachment_id, filename|
          next unless
            PDF_SUFFIX_REGEX.match?(filename) &&
            IncomingInvoice.with_source(email).none? { _1.pdf_file.file.filename.to_s == clean_filename(filename) }

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

          create_expense_invoice =
            (from && autocreate_expense_invoice_emails.any? { _1 === from }) ||
            (from_admin && /\A\s*expense\s/i.match?(email.text))

          pdf_file = PDFFile.create!(
            title: "Invoice",
            file:  { io: StringIO.new(attachment.data), filename: clean_filename(filename) }
          )

          if create_expense_invoice
            incoming_email_params[:internal_notes] = [
              incoming_email_params[:internal_notes],
              "Expense invoice created automatically."
            ].compact_blank
              .join("\n")
          end

          incoming_invoice = IncomingInvoice.create!(
            source: email,
            pdf_file:,
            **incoming_email_params
          )

          if create_expense_invoice
            incoming_invoice.create_expense_invoice!(
              pdf_file: PDFFile.new(original: pdf_file)
            ).then {
              ExpenseInvoices::Lexoffice::CreateFile.call_async _1
            }
          else
            Tasks::Create.call \
              taskable:   incoming_invoice,
              title:      "Incoming Invoice bearbeiten",
              identifier: :handle,
              if_absent:  :ignore
          end
        end
      end

      def clean_filename(filename)
        filename.tr(":", "_")
      end

      def autocreate_expense_invoice_emails = []
      def allow_emails_without_attachments  = []
      def generate_incoming_email_params(*) = {}
  end
end
