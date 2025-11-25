# frozen_string_literal: true

module Baseline
  module ActsAsEmailConfirmation
    extend ActiveSupport::Concern

    included do
      include HasEmail,
              HasTimestamps[:confirmed_at, :expired_at, :revoked_at]

      belongs_to :confirmable, polymorphic: true

      validates :email, presence: true
      validates :expired_at, presence: true

      validate on: :create, if: :confirmable do
        if confirmable.email_confirmations.unconfirmed.expired_after.any?
          errors.add :confirmable, message: "already has an unconfirmed and unexpired email confirmation"
        end

        if confirmable.email_confirmations.unconfirmed.exists?(email: confirmable.email) && email != confirmable.email
          errors.add :confirmable, message: "has not confirmed their current email, so a new confirmation for another email cannot be created"
        end
      end
    end

    def active?
      confirmed? && unrevoked?
    end

    def url
      case confirmable
      when User
        namespace  = confirmable.userable.class.to_s.underscore.pluralize.to_sym
        url_params = { t: confirmable.userable.login_token }
      when FreelancerRequest
        raise "implement"
      else raise "Unexpected confirmable: #{confirmable.class}"
      end

      Rails.application.routes.url_helpers.url_for [
        namespace,
        :email_confirmation,
        id: signed_id,
        **url_params
      ]
    end
  end
end
