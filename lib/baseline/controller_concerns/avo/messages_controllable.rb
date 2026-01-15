# frozen_string_literal: true

module Baseline
  module Avo
    module MessagesControllable
      def new
        super

        ::Messages::GeneratePartsFromI18n
          .call(@record)
          .slice(:subject, :sections)
          .then {
            @record.build_email_delivery(_1)
          }
      end

      def create
        @record.email_delivery.admin_user = ::Current.admin_user
        super
      end

      def create_success_action
        super

        @record
          .email_delivery
          ._do_send(_async: true)
      end

      def fill_record
        # The email delivery needs to exist before the params are assigned,
        # so that the email delivery's subject and sections can be assigned
        # via email_delivery_subject and email_delivery_sections_md.
        @record_to_fill.build_email_delivery
        super
      end
    end
  end
end
