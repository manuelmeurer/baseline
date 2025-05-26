# frozen_string_literal: true

module Baseline
  class InvoicingDetails
    module Lexoffice
      class UpsertContact < ApplicationService
        def call(invoicing_details)
          @invoicing_details = invoicing_details

          if @invoicing_details.invalid?
            raise Error, "Invoicing details are invalid."
          end

          if @invoicing_details.lexoffice_id.present?
            Baseline::External::Lexoffice.update_contact \
              @invoicing_details.lexoffice_id,
              params
          else
            Baseline::External::Lexoffice
              .create_contact(:customer, params)
              .then {
                @invoicing_details.update! lexoffice_id: _1
              }
          end
        end

        private

          def params
            person_or_company =
              if @invoicing_details.company_name.present?
                {
                  company: {
                    name:                 @invoicing_details.company_name,
                    allowTaxFreeInvoices: @invoicing_details.allow_tax_free?,
                    vatRegistrationId:    @invoicing_details.vat_id.presence
                  }
                }
              else
                {
                  person: {
                    salutation: @invoicing_details.fetch_value(:gender).then { t _1, scope: :genders, locale: :de },
                    firstName:  @invoicing_details.fetch_value(:first_name),
                    lastName:   @invoicing_details.fetch_value(:last_name)
                  }
                }
              end

            person_or_company.merge(
              addresses: {
                billing: [{
                  street:      @invoicing_details.street_1,
                  supplement:  @invoicing_details.street_2,
                  zip:         @invoicing_details.zip,
                  city:        @invoicing_details.city,
                  countryCode: @invoicing_details.country.alpha2
                }]
              }
            )
          end
      end
    end
  end
end
