# frozen_string_literal: true

module Baseline
  module LocalRecords
    class CommitFileToGithub < ApplicationService
      def call(local_record)
        message = [
          local_record.model_name.human,
          ("draft" if local_record.unpublished?)
        ].compact
          .join(" ")
          .then {
            "Add #{_1}: #{local_record.title}"
          }

        repo = `git -C #{Rails.root} remote get-url origin`
          .strip
          .delete_prefix("git@github.com:")
          .delete_prefix("https://github.com/")
          .delete_suffix(".git")

        Baseline::External::Github.commit_file \
          repo,
          local_record.file.delete_prefix("#{Rails.root}/"),
          message,
          "#{local_record.source}\n"
      end
    end
  end
end
