# frozen_string_literal: true

module Baseline
  module Lexoffice
    module Helpers
      extend self

      def tax_conditions(charge_vat)
        tax_type, tax_type_note = {
          yes:            [:net],
          no:             [:thirdPartyCountryService, I18n.t(:taxfree,        scope: :invoicing)],
          reverse_charge: [:externalService13b,       I18n.t(:reverse_charge, scope: :invoicing)]
        }.fetch(charge_vat.to_sym) {
          raise Error, "Unexpected charge VAT: #{charge_vat}"
        }

        {
          taxTypeNote: tax_type_note,
          taxType:     tax_type
        }.compact
      end

      def line_item(name, description, net_amount, charge_vat)
        {
          type:     "custom",
          quantity: 1,
          unitName: "Stück",
          name:,
          description:,
          unitPrice: {
            currency:          :EUR,
            netAmount:         net_amount.to_f.round(2),
            taxRatePercentage: charge_vat ? 19 : 0
          }
        }
      end
    end
  end
end
