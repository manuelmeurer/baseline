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
      photo
      remote_photo_url
    ]
    METHODS = USER_ATTRIBUTES
      .flat_map {
        [_1, :"#{_1}="]
      }.push(
        # Genders
        :male?,
        :female?,

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
        :subscription_ids,
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

      USER_ATTRIBUTES.each do |attribute|
        scope_name = :"with_#{attribute}"
        find_users =
          case
          when User.schema_columns.keys.include?(attribute)
            -> { User.where(attribute => _1) }
          when User.respond_to?(scope_name)
            -> { User.public_send(scope_name, _1) }
          end

        if find_users
          scope scope_name, -> {
            with_user(find_users.call(_1))
          }
        end

        delegate :"#{attribute}=", to: :user
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
      delegate :status_scopes, to: :User

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
