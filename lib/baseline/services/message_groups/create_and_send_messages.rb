# frozen_string_literal: true

module Baseline
  module MessageGroups
    class CreateAndSendMessages < ApplicationService
      def skippable?
        message_groups.none? ||
          message_groups.all? { _1.recipients.none? }
      end

      def call
        return if skippable?

        check_uniqueness on_error: :return

        message_groups.find_each do |message_group|
          message_group.recipients.limit(100).find_each do |recipient|
            message = InitializeMessage
              .call(message_group, recipient)
              .tap(&:save!)
          rescue
            ReportError.call Error, "Error creating message for message group.",
              recipient_gid:  recipient.to_gid.to_s,
              recipient_name: recipient.name
          else
            message.delivery._do_send(_async: true)
          end
        end
      end

      private

        def message_groups
          MessageGroup
            .sending_started
            .created_after(1.week.ago)
        end
    end
  end
end
