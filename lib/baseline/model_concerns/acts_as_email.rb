# frozen_string_literal: true

module Baseline
  module ActsAsEmail
    extend ActiveSupport::Concern

    BASE_URL = "https://mail.google.com/mail/u/#{Rails.application.env_credentials.mail_from!}".freeze

    included do
      include ActiveModel::Model,
              GlobalID::Identification

      attr_accessor :id

      def persisted? = true
    end

    class_methods do
      def find(id)
        new id:
      end

      def search_url(query)
        if query.is_a?(Hash)
          query = query.map do |key, value|
            if value.is_a?(Array)
              value = "(#{value.join(", ")})"
            end

            [key, value].join(":")
          end.join(" ")
        end

        File.join(BASE_URL, "#search/#{CGI.escape query}")
      end
    end

    def to_s = "Email from #{from}"

    def message
      unless Rails.env.production?
        return Data.define(:payload).new(
          payload: Data.define(:headers, :body, :parts).new(
            headers: [
              Data.define(:name, :value).new(
                name:  "From",
                value: "dummy@email.com"
              )
            ],
            body: Data.define(:data).new(
              data: String.new("Dummy email body") # mutable string needed for #force_encoding in #text
            ),
            parts: nil
          )
        )
      end

      @message ||= Baseline::External::Google::Oauth::Service
        .new(:gmail)
        .get_user_message("me", id)
    end

    def find_header(header_name, message_part = message.payload)
      message_part.headers
        &.detect { _1.name == header_name }
        &.value ||
      message_part.parts
        &.lazy
        &.map { find_header header_name, _1 }
        &.detect(&:present?)
    end

    def find_attachment_data(message_part = message.payload)
      {}.tap do |attachment_data|
        if message_part.filename.present?
          attachment_data[message_part.body.attachment_id] = message_part.filename
        end

        message_part.parts&.each { attachment_data.merge! find_attachment_data(_1) }
      end
    end

    def text(message_part = message.payload)
      while (text = message_part.body.data).blank?
        return "" unless message_part = message_part.parts&.first
      end

      text.force_encoding("UTF-8")
    end

    def from
      find_header("From").presence&.then { _1[/\s+<([^>]+)>\z/, 1] || _1 } \
        or raise Error, %(Could not find "From" header.)
    end

    def subject
      find_header("Subject") \
        or raise Error, %(Could not find "Subject" header.)
    end

    def sent_at
      Time.at(message.internal_date.to_f / 1000)
    end

    def url
      File.join(BASE_URL, "#all/#{id}")
    end
  end
end
