# frozen_string_literal: true

module Baseline
  module Errors
    class Issue < ApplicationRecord
      self.table_name = Baseline::Errors.table_name

      scope :recent_first, -> { order(last_seen_at: :desc, id: :desc) }
      scope :resolved, -> { where.not(resolved_at: nil) }
      scope :unresolved, -> { where(resolved_at: nil) }

      def resolve!
        update!(resolved_at: Time.current)
      end

      def unresolve!
        update!(resolved_at: nil)
      end

      def resolved? = resolved_at.present?
    end
  end
end
