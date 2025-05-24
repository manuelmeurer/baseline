# frozen_string_literal: true

module Baseline
  module ActsAsInvoicingDetails
    extend ActiveSupport::Concern

    included do
      include HasCountry,
              HasFirstAndLastName,
              HasGender

      validates :gender, presence: { unless: :company_name }
      validates :first_name, presence: { unless: :company_name }
      validates :last_name, presence: { unless: :company_name }
      validates :street_1, presence: true
      validates :zip, presence: true
      validates :city, presence: true
      validates :country, presence: true
      validates :vat_id, format: { with: /\A[A-Z]{2}[A-Z0-9]{1,12}\z/, allow_nil: true }
      validates :iban, format: { with: /\A[A-Z]{2}[0-9]{2}[A-Za-z0-9]{11,30}\z/, allow_nil: true }

      %i[iban vat_id].each do |attribute|
        normalizes attribute,
          with: -> { _1.gsub(/\s+/, "").upcase }
      end
    end

    def to_s                  = "Invoicing details for #{kunde}"
    def allow_no_vat?         = !eu_country?
    def allow_reverse_charge? = eu_country_except_germany? && vat_id.present?
    def allow_tax_free?       = allow_reverse_charge? || allow_no_vat?

    def full_address
      [
        street_1,
        street_2,
        [zip, city].compact_blank.join(" ")
      ].compact_blank
        .join("\n")
    end

    def lexoffice_url
      if lexoffice_id.present?
        Baseline::External::Lexoffice.contact_url(lexoffice_id)
      end
    end
  end
end
