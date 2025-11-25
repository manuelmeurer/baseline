# frozen_string_literal: true

module Baseline
  class CreateAndSyncDbBackup < ApplicationService
    def call
      check_uniqueness

      unless system("bin/db backup")
        raise Error, "Error creating DB backup."
      end

      unless system("bin/db sync")
        raise Error, "Error syncing DB backup."
      end
    end
  end
end
