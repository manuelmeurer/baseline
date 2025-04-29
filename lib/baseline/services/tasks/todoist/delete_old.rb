# frozen_string_literal: true

module Baseline
  module Tasks
    module Todoist
      class DeleteOld < ApplicationService
        def call
          Task
            .too_old_for_todoist
            .where.not(todoist_id: nil)
            .each do |task|

            unless access_token = task.responsible.todoist_access_token.presence
              raise Error, "Task #{task.id} has Todoist ID, but responsible #{task.responsible} has no Todoist access token."
            end

            Baseline::External::Todoist.call \
              access_token,
              :delete_task,
              task.todoist_id

            task.update! todoist_id: nil
          end
        end
      end
    end
  end
end
