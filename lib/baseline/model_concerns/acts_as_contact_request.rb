# frozen_string_literal: true

module Baseline
  module ActsAsContactRequest
    def self.[](kinds)
      Module.new do
        extend ActiveSupport::Concern

        included do
          include HasEmail,
                  HasFullName,
                  HasLocale,
                  HasTimestamps[:ignored_at],
                  Searchable[%i[name email company message]]

          enum :kind, kinds,
            validate: true

          has_many :messages,
            class_name: "ContactRequestMessage",
            as:         :recipient,
            dependent:  :destroy

          validates :name, presence: true
          validates :email, presence: true
          validates :message, presence: true
        end

        class_methods do
          # This will generate corresponding scopes and methods.
          def status_scopes
            {
              ignored:  nil,
              messaged: %i[with_messages],
              pending:  %i[unignored without_messages]
            }
          end
        end

        def to_s = "Contact request from #{name} (#{email})"

        def fields = %i[name email phone company message]
      end
    end
  end
end
