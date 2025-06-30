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
        message_parts = [
          "*#{notification.title} [#{Rails.application.class.module_parent_name.titleize}]*",
          notification.details
        ]
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
          message_parts.concat [
            %(#{notifiable.model_name.human} "#{notifiable}"),
            admin_url
          ]
        end

        Baseline::External::SlackSimple.call_async \
          :post_message,
          SLACK_CHANNEL_ID,
          message_parts.join("\n")

        notification
      end
    end
  end
end
