# frozen_string_literal: true

module Baseline
  module Backups
    class ValidateSyncedDbBackups < ApplicationService
      def call
        check_uniqueness
        run_command("bin/db validate_synced")
      end
    end
  end
end
