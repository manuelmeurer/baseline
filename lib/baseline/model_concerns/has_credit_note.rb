# frozen_string_literal: true

module Baseline
  module HasCreditNote
    extend ActiveSupport::Concern

    included do
      has_one :credit_note,
        as:         :creditable,
        inverse_of: :creditable,
        dependent:  :destroy

      accepts_nested_attributes_for :credit_note, update_only: true

      delegate \
        :pdf_file,     :pdf_file=, :build_pdf_file,
        :number,       :number=,
        :date,         :date=,
        :amount,       :amount=,
        :lexoffice_id, :lexoffice_id=, :lexoffice_url,
        to:        :credit_note,
        allow_nil: true
    end
  end
end
