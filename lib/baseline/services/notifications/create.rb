# frozen_string_literal: true

module Baseline
  module Notifications
    class Create < ApplicationService
      SLACK_CHANNEL_ID = "C026MQQRK7U" # #notifications

      def call(every: nil, **args)
        return if
          every &&
          Notification
            .where(args.except(:details))
            .last
            .then { _1 && _1.created_at + every > Time.current }

        notification = Notification.create!(args)
        notifiable   = notification.notifiable
        message = [
          "*#{notification.title}*",
          notification.details,
          if notifiable
            [
              %(#{notifiable.class.to_s.titleize} "#{notifiable}"),
              url_for([:admin, notifiable])
            ]
          end
        ].flatten
          .compact
          .join("\n")

        post_to_slack \
          notification,
          message

        notification
      end

      private

        def post_to_slack(notification, message)
          Baseline::External::SlackSimple.call_async \
            :post_message,
            SLACK_CHANNEL_ID,
            message
        end
    end
  end
end
