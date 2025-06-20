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
            admin_url =
              defined?(::Avo) ?
                ::Avo::Engine
                  .routes
                  .url_helpers
                  .url_for([
                    :resources,
                    notifiable
                  ]) :
                url_for([:admin, notifiable])
            [
              %(#{notifiable.model_name.human} "#{notifiable}"),
              admin_url
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
