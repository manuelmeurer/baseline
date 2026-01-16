# frozen_string_literal: true

module Baseline
  module External
    class SlackSimple < ::External::Base
      add_action :post_message do |channel_id, text|
        # https://docs.slack.dev/reference/methods/chat.postMessage/
        client.chat_postMessage \
          channel: channel_id,
          text:
      end

      private

        memo_wise def client
          Rails
            .application
            .env_credentials
            .slack_token!
            .then {
              ::Slack::Web::Client.new(token: _1)
            }
        end
    end
  end
end
