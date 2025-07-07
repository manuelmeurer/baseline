# frozen_string_literal: true

module Baseline
  class CreateDbBackup < ApplicationService
    def call
      check_uniqueness

      return unless Time.current.hour.in?([1, 2, 13, 14])

      track_last_run do |last_run_at = 1.day.ago|
        if last_run_at < 9.hours.ago
          unless system("bin/db backup")
            raise Error, "Error creating DB backup."
          end
        end
      end
    end
  end
end
