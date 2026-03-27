# frozen_string_literal: true

module Baseline
  module MessageGroups
    class InitializeMessage < ApplicationService
      def call(message_group, recipient, delivery_method: nil)
        if recipient.deactivated?
          raise Error, "Refusing to initialize message to deactivated #{recipient.class}."
        end
        if delivery_method&.then { message_group.valid_delivery_methods.exclude?(_1.to_sym) }
          raise Error, "#{delivery_method} is not a valid delivery method for this message group."
        end

        parts = Messages::GeneratePartsFromI18n.call(message_group, recipient)
        delivery_method ||= set_delivery_method(message_group, recipient)
        delivery = generate_delivery(delivery_method, recipient, parts)

        recipient.messages.build \
          delivery:,
          group:       message_group,
          kind:        message_group.kind,
          messageable: message_group.messageable
      end

      private

        def set_delivery_method = :email

        def generate_delivery(delivery_method, recipient, parts)
          unless delivery_method == :email
            raise Error, "Unexpected delivery method: #{delivery_method}"
          end

          EmailDelivery.new \
            recipients: [recipient],
            **parts.slice(:subject, :sections)
        end
    end
  end
end
