# frozen_string_literal: true

module Baseline
  module ActsAsSubscription
    extend ActiveSupport::Concern

    included do
      has_many :user_subscriptions, dependent: :destroy, inverse_of: :subscription
      has_many :users, through: :user_subscriptions, inverse_of: :subscriptions

      validates :identifier,
        presence:   true,
        uniqueness: true
    end

    class_methods do
      def valid_identifiers_for(user) = identifiers

      def method_missing(method, ...)
        if identifiers.include?(method.to_s)
          where(identifier: method).first_or_create!
        else
          super
        end
      end
    end

    def title
      I18n.t identifier,
        scope:   :subscriptions,
        default: identifier.titleize
    end

    def to_param = identifier
  end
end
