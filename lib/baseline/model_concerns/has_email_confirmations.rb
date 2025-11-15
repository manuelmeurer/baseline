# frozen_string_literal: true

module Baseline
  module HasEmailConfirmations
    extend ActiveSupport::Concern

    included do
      has_many :email_confirmations, as: :confirmable, dependent: :destroy

      scope :email_confirmed, -> {
        EmailConfirmation
          .confirmed
          .unrevoked
          .where("#{table_name}.email = email_confirmations.email")
          .where(id:
            EmailConfirmation
              .select("MAX(id)")
              .group(:confirmable_id, :confirmable_type, :email)
          ).then {
            joins(:email_confirmations)
              .merge(_1)
          }
      }
    end

    def email_confirmed?
      current_email_confirmation&.active?
    end

    def current_email_confirmation
      email_confirmations
        .where(email:)
        .last
    end
  end
end
