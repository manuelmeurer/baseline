# frozen_string_literal: true

module Baseline
  module Tasks
    module Todoist
      class CreateAll < ApplicationService
        def call(admin_user)
          unless admin_user.todoist_access_token
            raise Error, "Admin user #{admin_user} does not have a Todoist access token."
          end

          admin_user
            .responsible_tasks
            .where(todoist_id: nil)
            .find_each(order: :desc)
            .with_index do |task, index|

            # Rate limit is 1,000 requests per 15 minutes, so let's aim for one request per second.
            # https://developer.todoist.com/rest/v2/#request-limits
            Update.call_in (index + 1).seconds, task
          end
        end
      end
    end
  end
end
