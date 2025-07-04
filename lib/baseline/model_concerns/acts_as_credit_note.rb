# frozen_string_literal: true

module Baseline
  module ActsAsCreditNote
    extend ActiveSupport::Concern

    included do
      include HasChargeVAT[:creditable],
              HasPDFFiles[many: false],
              TouchAsync[:creditable]

      belongs_to :creditable, polymorphic: true

      validates :date, presence: true
      validates :description, presence: true
      validates :pdf_file, presence: { if: :lexoffice_id }
      validates :number, presence: { if: :lexoffice_id }
      validates :amount_cents,
        presence: true,
        numericality: {
          allow_nil:    true,
          only_integer: true,
          greater_than: 0
        }

      delegate :invoicing_details, to: :creditable

      attribute :date, default: -> { Date.current }

      monetize :amount_cents
    end

    def lexoffice_url
      if lexoffice_id.present?
        Baseline::External::Lexoffice.voucher_url(lexoffice_id)
      end
    end

    def to_s
      "Credit note for #{creditable.class.model_name.human}"
    end
  end
end
