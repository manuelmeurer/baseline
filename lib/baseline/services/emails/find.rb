# frozen_string_literal: true

module Baseline
  module Emails
    class Find < ApplicationService
      def call(query)
        gmail = External::Google::Oauth::Service.new(:gmail)
        query = query
          .transform_values {
            case
            when _1.is_a?(String)         then _1
            when _1.respond_to?(:iso8601) then _1.iso8601
            else raise Error, "Unexpected query value: #{_1} (#{_1.class})"
            end
          }.map { [_1, _2].join(":") }
          .join(" ")

        gmail.fetch_all(items: :messages) do |token|
          gmail.list_user_messages \
            "me",
            q:          query,
            page_token: token
        end.map {
          Email.new id: _1.id
        }
      end
    end
  end
end
