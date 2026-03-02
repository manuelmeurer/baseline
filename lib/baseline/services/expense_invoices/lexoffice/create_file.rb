# frozen_string_literal: true

module Baseline
  module ExpenseInvoices
    module Lexoffice
      class CreateFile < ApplicationService
        def call(expense_invoice)
          if expense_invoice.lexoffice_id.present?
            raise Error, "Expense invoice already has a Lexoffice ID."
          end

          file = expense_invoice
            .pdf_file
            .file

          pathname = Rails.root.join(
            "tmp",
            "expense_invoices",
            expense_invoice.id.to_s,
            file.filename.to_s
          )

          unless pathname.exist?
            FileUtils.mkdir_p pathname.dirname
            file
              .download
              .then {
                File.binwrite pathname, _1
              }
          end

          lexoffice_id = Baseline::External::Lexoffice.create_file(pathname)

          expense_invoice.update! lexoffice_id:
        end
      end
    end
  end
end
