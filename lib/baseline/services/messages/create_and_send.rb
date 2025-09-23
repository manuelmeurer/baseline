# frozen_string_literal: true

module Baseline
  module Messages
    class CreateAndSend < ApplicationService
      def call(
        message_or_params,
        delivery_method: nil,
        send_async:      true,
        subject:         nil,
        sections:        nil,
        admin_user:      nil,
        send_in:         nil,
        recipients:      nil,
        cc_recipients:   [],
        bcc_recipients:  [],
        reply_to:        nil)

        message = message_or_params.if(Hash) {
          Message.new(_1)
        }

        unless message.delivery
          delivery_method ||=
            message.recipient.try(:slack_user)&.active? ?
              :slack :
              :email

          parts = ::Messages::GeneratePartsFromI18n.call(message, admin_user:)

          case delivery_method.to_sym
          when :slack

            message.build_slack_delivery \
              admin_user:,
              body: parts.fetch(:slack_body)

          when :email

            message.build_email_delivery \
              admin_user:,
              cc_recipients:,
              bcc_recipients:,
              reply_to:,
              recipients: recipients || [message.recipient],
              subject:    subject    || parts.fetch(:subject),
              sections:   sections   || parts.fetch(:sections)

          else raise Error, "Unexpected delivery method: #{delivery_method}"
          end
        end

        if defined?(SlackDelivery) && message.delivery.is_a?(SlackDelivery)
          unless message.recipient.slack_user.active?
            raise Error, "Recipient's Slack user is not active."
          end

          prepare_slack_delivery(message)
        end

        message.save!

        message
          .delivery
          ._do_send \
            _async: send_async,
            _after: send_in

        message
      end
    end
  end
end
