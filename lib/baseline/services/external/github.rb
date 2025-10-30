# frozen_string_literal: true

module Baseline
  module External
    class Github < ::External::Base
      add_action :dispatch_workflow do |repo, id, ref, **inputs|
        Poller.poll retries: 10, errors: Octokit::InternalServerError do
          client.workflow_dispatch \
            repo, id, ref,
            inputs:
        end
      end

      add_action :commit_file do |repo, path, message, content|
        client.create_contents \
          repo,
          path,
          message,
          content
      end

      private

        def client
          @client ||= Octokit::Client.new
        end
    end
  end
end
