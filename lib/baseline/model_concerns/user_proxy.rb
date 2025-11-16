# frozen_string_literal: true

module Baseline
  module UserProxy
    extend ActiveSupport::Concern

    USER_METHODS = %i[
      email
      first_name
      gender
      language
      last_name
      locale
      login_token
      name
    ].concat(
      User.genders.keys.map { :"#{_1}?" }
    ).freeze
    EMAIL_CONFIRMATION_METHODS = %i[
      current_email_confirmation
      email_confirmations
      email_confirmed?
    ].freeze
    DEACTIVATABLE_METHODS = %i[
      active?
      deactivate!
      deactivated_after?
      deactivated_at
      deactivated_before?
      deactivated_between?
      deactivated?
      deactivation
      deactivations
      reactivate!
    ].freeze
    SUBSCRIPTION_METHODS = %i[
      subscribed
      subscribed?
      subscriptions
      unsubscribe
      update_subscriptions
    ]
    METHODS = (
      USER_METHODS +
      EMAIL_CONFIRMATION_METHODS +
      DEACTIVATABLE_METHODS +
      SUBSCRIPTION_METHODS
    ).flat_map do |method|
      [
        method,
        :"#{method}=".if(-> { User.instance_methods.exclude?(_1) })
      ]
    end.compact.freeze

    SCOPES = %i[
      active
      deactivated
      deactivated_after
      deactivated_before
      deactivated_between
      email_confirmed
      subscribed
    ].freeze

    included do
      delegate *METHODS, :to_s, to: :user

      SCOPES.each do |scope_name|
        scope scope_name, ->(*args) {
          with_user(User.public_send(scope_name, *args))
        }
      end

      USER_METHODS
        .intersection(User.column_names.map(&:to_sym))
        .each do |column|
          scope :"with_#{column}", -> {
            with_user(User.where(column => _1))
          }
        end

      validate if: :user do
        user
          .tap(&:valid?)
          .errors
          .each do |error|

          errors.add :user, "#{error.attribute} #{error.message}"
        end
      end
    end

    class_methods do
      def method_missing(method, ...)
        unless respond_to?(:with_first_name)
          ReportError.call "Expected #{self} to have method with_first_name."
          return super
        end

        with_first_name(method.capitalize).first or
          super
      end
    end

    def user = super || build_user
  end
end
