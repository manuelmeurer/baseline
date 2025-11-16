# frozen_string_literal: true

module Baseline
  module UserProxy
    extend ActiveSupport::Concern

    USER_ATTRIBUTES = %i[
      email
      first_name
      last_name
      name
      gender
      locale
      language
      login_token
    ]
    METHODS = USER_ATTRIBUTES
      .flat_map {
        [_1, :"#{_1}="]
      }.push(
        *User.genders.keys.map { :"#{_1}?" },

        # Dummy image attachment
        :dummy_photo,
        :photo_or_dummy,

        # Email confirmations
        :current_email_confirmation,
        :email_confirmations,
        :email_confirmed?,

        # Deactivatable
        :active?,
        :deactivate!,
        :deactivated_after?,
        :deactivated_at,
        :deactivated_before?,
        :deactivated_between?,
        :deactivated?,
        :deactivation,
        :deactivations,
        :deactivations=,
        :reactivate!,

        # Subscriptions
        :subscribed,
        :subscribed?,
        :subscriptions,
        :unsubscribe,
        :update_subscriptions
      ).freeze

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

      if User.db_and_table_exist?
        USER_ATTRIBUTES
          .intersection(User.column_names.map(&:to_sym))
          .each do |column|
            scope :"with_#{column}", -> {
              with_user(User.where(column => _1))
            }
          end
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
