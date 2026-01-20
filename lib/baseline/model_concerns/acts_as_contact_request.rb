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

          %i[with without].each do |prefix|
            scope :"#{prefix}_messages_except_created", -> {
              public_send \
                :"#{prefix}_messages",
                ContactRequestMessage.where.not(kind: :created)
            }
          end

          validates :name, presence: true
          validates :email, presence: true
          validates :message, presence: true
        end

        class_methods do
          # This will generate corresponding scopes and methods.
          def status_scopes
            {
              ignored:                 nil,
              messaged_except_created: %i[with_messages_except_created],
              pending:                 %i[unignored without_messages_except_created]
            }
          end
        end

        def to_s = "Contact request from #{name} (#{email})"

        def fields = %i[name email phone company message]
      end
    end
  end
end
