# frozen_string_literal: true

module Baseline
  module Backups
    class CreateAndSyncDbBackup < ApplicationService
      def call
        check_uniqueness

        run_command("bin/db backup")
        run_command("bin/db sync")
      end
    end
  end
end
