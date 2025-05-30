# frozen_string_literal: true

module Baseline
  module HasChargeVAT
    def self.[](invoicing_details_owner)
      Module.new do
        extend ActiveSupport::Concern

        included do
          enum :charge_vat,
            %i[yes no reverse_charge],
            prefix:   true,
            validate: true

          validate if: :charge_vat do
            if (!allow_no_vat?         && charge_vat_no?) ||
               (!allow_reverse_charge? && charge_vat_reverse_charge?)

              errors.add :charge_vat, message: %(must not be "#{charge_vat}")
            end
          end

          define_method :invoicing_details do
            public_send(invoicing_details_owner).invoicing_details
          end

          delegate \
            :allow_no_vat?,
            :allow_reverse_charge?,
            :allow_tax_free?,
            to:        :invoicing_details,
            allow_nil: true
        end

        def set_charge_vat
          self.charge_vat =
            case
            when allow_no_vat?         then :no
            when allow_reverse_charge? then :reverse_charge
            else                            :yes
            end
        end
      end
    end
  end
end
