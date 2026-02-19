# frozen_string_literal: true

module Baseline
  module EmailConfirmations
    class Create < ApplicationService
      ThrottledError = Class.new(Error)

      def call(send_message: true, **args)
        email_confirmation = EmailConfirmation
          .new(args)
          .tap {
            _1.confirmable ||= ::Current.user
            _1.email       ||= _1.confirmable.email
            _1.expired_at  ||= 15.minutes.from_now
          }

        if send_message
          unless email_confirmation.confirmable.is_a?(User)
            raise Error, "Can only send email confirmation messages to users."
          end

          messages = email_confirmation
            .confirmable
            .messages
            .email_confirmation

          raise ThrottledError if
            messages.created_after(1.minute.ago).exists? ||
            messages.created_after(1.day.ago).size >= 10
        end

        email_confirmation.save!

        if send_message
          messages
            .build(messageable: email_confirmation)
            .tap { _1.recipient.email = email_confirmation.email }
            ._do_create_and_send \
              delivery_method: :email,
              send_async:      false
        end

        email_confirmation
      end
    end
  end
end
