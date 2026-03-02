# frozen_string_literal: true

module Baseline
  module ActsAsExpenseInvoice
    extend ActiveSupport::Concern

    included do
      include Baseline::HasPDFFiles[many: false]

      belongs_to :incoming_invoice

      validates :incoming_invoice, uniqueness: true
    end

    def title = "Expense invoice from #{incoming_invoice}"
  end
end
