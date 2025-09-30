# frozen_string_literal: true

module Baseline
  module EmailDeliveries
    class Send < ApplicationService
      RETRY_ERRORS = [
        (Mjml::Parser::ParseError if defined?(Mjml)),
        Net::ProtocolError,
        OpenSSL::SSL::SSLError,
        Timeout::Error
      ].freeze

      def call(email_delivery)
        if email_delivery.sent?
          raise Error, "Email delivery has already been sent."
        end
        if email_delivery.rejected_emails.any?
          raise Error, "Email delivery already has rejected emails."
        end
        if email_delivery.recipients.values.any?(&:blank?)
          raise Error, "One or more recipients don't have an email."
        end

        if email_delivery.scheduled? && Time.current < email_delivery.scheduled_at
          self.class.call_at email_delivery.scheduled_at, email_delivery
          return
        end

        if email_delivery.recipients.keys.any? { !_1.respond_to?(:test_user?) || !_1.test_user? } &&
          EmailDelivery.sent_after(1.week.ago).clones_of(email_delivery).any?

          raise Error, "Refusing to send duplicate email delivery."
        end

        mail = ApplicationMailer.email_delivery(email_delivery)

        begin
          Poller.poll retries: 10, errors: RETRY_ERRORS do
            mail.deliver_now
          end
        rescue Poller::TooManyAttemptsError
          raise Error, "Could not send email."
        rescue => error
          if defined?(Postmark::InactiveRecipientError) && error.is_a?(Postmark::InactiveRecipientError)
            email_delivery.rejected_emails += error.recipients
          else
            raise error
          end
        else
          email_delivery.message_id = mail.message_id

          mail.body.parts.each do |part|
            part
              .content_type[%r{\Atext/([a-z]+)}, 1]
              &.then {
                {
                  html:  :html_content,
                  plain: :text_content
                }[_1.to_sym]
              }&.then {
                email_delivery.public_send "#{_1}=", part.body.raw_source
              }
          end

          if email_delivery.html_content.blank? || email_delivery.text_content.blank?
            mail_body_parts = mail
              .body
              .parts
              .index_with(&:content_type)
              .transform_values do |value|
                value
                  .if(-> { _1.respond_to? :body },       &:body)
                  .if(-> { _1.respond_to? :raw_source }, &:raw_source)
                  .truncate(100)
              end
              .to_json

            ReportError.call "No HTML or text content.",
              email_delivery_id: email_delivery.id,
              mail_body_parts:
          end
        end

        if email_delivery.persisted?
          email_delivery.save!

          # Only mark email delivery as sent if it's already saved,
          # so that we can send test emails that should not be saved.
          if email_delivery.message_id
            email_delivery.sent!
          end
        end
      end
    end
  end
end
