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
          # In Uplink, we will replace our custom CMS with Avo step by step.
          # This means that some resources already have an Avo URL, for others we will want to use the custom admin URL.
          # Once the custom CMS is fully replaced, we can simplify this logic and always use the Avo URL.
          if defined?(::Avo)
            admin_url = suppress NoMethodError do
              ::Avo::Engine
                .routes
                .url_helpers
                .url_for([
                  :resources,
                  notifiable
                ])
            end
          end
          admin_url ||=
            begin
              url_for([:admin, notifiable])
            rescue NoMethodError
              ReportError.call Error, "Could not generate admin URL for notifiable",
                notifiable_class: notifiable.class
            end
          message_parts.concat [
            %(#{notifiable.model_name.human} "#{notifiable}"),
            admin_url
          ].compact
        end

        ::External::SlackSimple.call_async \
          :post_message,
          SLACK_CHANNEL_ID,
          message_parts.join("\n")

        notification
      end
    end
  end
end
