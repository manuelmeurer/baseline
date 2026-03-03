# frozen_string_literal: true

module Baseline
  module ActsAsIncomingInvoice
    extend ActiveSupport::Concern

    included do
      include HasPDFFiles[many: false],
              HasTimestamps[:processed_at, :ignored_at]

      has_one :expense_invoice

      has_many :freelancer_invoices, through: :engagement_invoice

      validates :pdf_file, presence: true
      validates :ignored_at, absence: { if: :expense_invoice }

      scope :with_email, -> { where(email_gid: _1.to_gid.to_s) }
    end

    def email
      email_gid&.then {
        GlobalID.find!(_1)
      }
    end

    def email=(email)
      self.email_gid = email.if(Email) { _1.to_gid.to_s }
    end
  end
end
