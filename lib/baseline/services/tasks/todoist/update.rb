# frozen_string_literal: true

module Baseline
  module Tasks
    module Todoist
      class Update < ApplicationService
        def call(task_or_attributes, changes = {})
          # If `task_or_attributes` is a Hash, this means that the task was deleted.
          if task_or_attributes.is_a?(Hash)
            task = Task.new(task_or_attributes)
            if task.todoist_id
              External::Todoist.call \
                task.responsible.todoist_access_token,
                :delete_task,
                task.todoist_id
            end
            return
          end

          task = task_or_attributes
          changes = changes.symbolize_keys
          dependent_attributes = %i[
            title
            details
            taskable_id
            taskable_type
            priority
            done_at
            due_on
          ]
          task_attributes = {
            content:     task.title,
            description: task.todoist_description,
            priority:    task.todoist_priority,
            due_date:    task.due_on.iso8601
          }

          # Delete from old responsible
          if task.todoist_id && changes.values_at(:responsible_id, :responsible_type).any? { _1&.first }
            old_responsible_class = (changes[:responsible_type]&.first || task.responsible_type).constantize
            old_responsible       = old_responsible_class.find(changes[:responsible_id]&.first || task.responsible_id)

            task.with responsible: old_responsible do
              if old_access_token = task.responsible_admin_todoist_access_token
                External::Todoist.call \
                  old_access_token,
                  :delete_task,
                  task.todoist_id
              end
            end

            task.update! todoist_id: nil
          end

          if access_token = task.responsible_admin_todoist_access_token
            case
            when task.todoist_id
              if changes.empty? || changes.keys.intersect?(dependent_attributes)
                External::Todoist.call \
                  access_token,
                  :update_task,
                  task.todoist_id,
                  task.done?,
                  task_attributes
              end
            when !task.too_old_for_todoist?
              External::Todoist.call(
                access_token,
                :create_task,
                task.done?,
                task_attributes
              ).then {
                task.update! todoist_id: _1.fetch(:id)
              }
            end
          end
        end
      end
    end
  end
end
