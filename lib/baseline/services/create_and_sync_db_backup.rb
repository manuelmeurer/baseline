# frozen_string_literal: true

require "open3"

module Baseline
  class CreateAndSyncDbBackup < ApplicationService
    def call
      check_uniqueness

      [
        "bin/db backup",
        "bin/db sync"
      ].each do |command|
        stdout, stderr, status = Open3.capture3(command)
        unless status.success?
          raise Error, "Error running #{command}.\nSTDOUT: #{stdout}\nSTDERR: #{stderr}"
        end
      end
    end
  end
end
