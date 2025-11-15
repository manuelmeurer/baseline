# frozen_string_literal: true

module Baseline
  module ActsAsDeactivation
    extend ActiveSupport::Concern

    AFTER_DEACTIVATE_METHOD = :after_deactivate.freeze
    AFTER_REACTIVATE_METHOD = :after_reactivate.freeze

    included do
      include HasTimestamps[:revoked_at],
              TouchAsync[:deactivatable]

      belongs_to :deactivatable, polymorphic: true
      belongs_to :initiator, polymorphic: true, required: false

      validates :reason, presence: true, inclusion: { in: -> { _1.valid_reasons }, if: :deactivatable, allow_nil: true }
      validates :details, presence: { if: proc { reason == "other" }, message: %(can't be blank if reason is "other") }

      validate do
        if unrevoked? && deactivatable.deactivations.unrevoked.excluding(self).exists?
          errors.add :deactivatable, message: "#{deactivatable} is already deactivated"
        end
      end

      after_commit on: :create do
        if deactivatable.respond_to?(AFTER_DEACTIVATE_METHOD, true)
          begin
            deactivatable.send(AFTER_DEACTIVATE_METHOD)
          rescue
            ReportError.call "Error calling `#{AFTER_DEACTIVATE_METHOD}` after deactivating #{deactivatable}.",
              deactivatable_gid: deactivatable.to_gid.to_s
          end
        end
      end

      after_commit on: :update do
        if revoked? && revoked_at_changed? && deactivatable.respond_to?(AFTER_REACTIVATE_METHOD, true)
          begin
            deactivatable.send(AFTER_REACTIVATE_METHOD)
          rescue
            ReportError.call "Error calling `#{AFTER_REACTIVATE_METHOD}` after reactivating #{deactivatable}.",
              deactivatable_gid: deactivatable.to_gid.to_s
          end
        end
      end
    end

    def valid_reasons = {}

    def to_s
      [
        "Deactivation of #{deactivatable}",
        ("(revoked)" if revoked?)
      ].compact.join(" ")
    end
  end
end
