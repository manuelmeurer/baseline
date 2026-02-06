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

        if @record.recipient.tasks.undone.find_by(identifier: :handle)&.done!
          add_flash :notice, "Task to handle #{@record.recipient.class.model_name.human} marked as done."
        end

        if @record.try(:create_follow_up_task)
          days =
            @record.recipient.is_a?(ContactRequest) &&
              (@record.recipient.agency? || @record.recipient.recruiter?) ?
            7 :
            1
          due_on = days.business_days_from.to_date

          I18n.with_locale :de do
            Tasks::Create.call \
              due_on:,
              taskable:    @record,
              responsible: ::Current.admin_user,
              title:       "Follow-up",
              details:     "Antwort? Nachhaken!",
              priority:    :high
          end

          add_flash :notice, "Task to follow up created for #{l due_on}."
        end
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
