# frozen_string_literal: true

module Baseline
  module Deactivatable
    extend ActiveSupport::Concern

    included do
      has_many :deactivations,
        as:        :deactivatable,
        dependent: :destroy

      scope :deactivated, ->(range = nil) {
        Deactivation
          .unrevoked
          .if(range) { _1.where(created_at: _2) }
          .then { with_deactivations(_1) }
      }
      scope :deactivated_before,  -> { deactivated(.._1) }
      scope :deactivated_after,   -> { deactivated(_1..) }
      scope :deactivated_between, -> { deactivated(_1.._2) }

      scope :active, ->(range = nil) {
        Deactivation
          .unrevoked
          .if(range) { _1.where(created_at: _2) }
          .then { without_deactivations(_1) }
      }
      scope :active_before,  -> { active(.._1) }
    end

    def deactivation              = deactivations.detect(&:unrevoked?)
    def active?                   = !deactivation
    def deactivated?              = !!deactivation
    def deactivated_at            = deactivation&.created_at
    def deactivated_before?(time) = deactivated_at&.before?(time)
    def deactivated_after?(time)  = deactivated_at&.after?(time)

    def deactivated_between?(start_time, end_time)
      deactivated_at&.then {
        (start_time..end_time).cover?(_1)
      }
    end

    def deactivate!(**params)
      if deactivated?
        raise "#{self.class.model_name.human} is already deactivated."
      end

      deactivations
        .build(**params)
        .tap { save! }
        .save!
    end

    def reactivate!
      if active?
        raise "#{self.class.model_name.human} is already active."
      end

      deactivation
        .tap { _1.revoked_at = Time.current }
        .tap { save! }
        .save!
    end
  end
end
