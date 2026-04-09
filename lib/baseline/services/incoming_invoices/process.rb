# frozen_string_literal: true

module Baseline
  module IncomingInvoices
    class Process < ApplicationService
      EXPENSE_PREFIX = /\A\s*expense\s/i

      def call(incoming_invoice)
        if incoming_invoice.processed?
          raise Error, "Incoming invoice #{incoming_invoice.id} has already been processed."
        end

        create_expense_invoice = if incoming_invoice.email
          autocreate_expense_invoice_emails.any? {
            _1 === incoming_invoice.email.from ||
            _1 === incoming_invoice.email.real_from
          } || (
            incoming_invoice.email.from_admin? &&
            incoming_invoice.email.text.match?(EXPENSE_PREFIX)
          )
        end

        case
        when create_expense_invoice
          incoming_invoice.update internal_notes: [
            incoming_invoice.internal_notes,
            "Expense invoice created automatically."
          ].compact_blank.join("\n")
          incoming_invoice.create_expense_invoice!(
            pdf_file: PDFFile.new(original: incoming_invoice.pdf_file)
          )._do_lexoffice__create_file(_async: true)
        when respond_to?(:do_process, true)
          @incoming_invoice = incoming_invoice
          do_process
        end

        incoming_invoice.processed!
      end

      private

        def autocreate_expense_invoice_emails = []
    end
  end
end
