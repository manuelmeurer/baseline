# frozen_string_literal: true

module Baseline
  module TodoistEvents
    class Process < ApplicationService
      def call(todoist_event)
        if todoist_event.processed?
          raise Error, "Todoist event #{todoist_event.id} has already been processed."
        end

        if todoist_event.relevant?
          Task.processing_todoist_event = true
          begin
            do_process todoist_event
          ensure
            Task.processing_todoist_event = false
          end
        end

        todoist_event.processed!
      end

      private

        def create_task(todoist_event, attributes)
          Tasks::Create.call \
            responsible: todoist_event.admin_user,
            todoist_id:  todoist_event.event_data.fetch("id"),
            if_absent:   :ignore,
            **attributes
        end

        def do_process(todoist_event)
          task_attributes = {
            title:               todoist_event.event_data.fetch("content"),
            todoist_description: todoist_event.event_data.fetch("description"),
            due_on:              todoist_event.due_on,
            todoist_priority:    todoist_event.event_data.fetch("priority")
          }

          case todoist_event.kind
          when "item:added"
            # Only create the task if we're sure that it wasn't created by our CMS via the Todoist API.
            unless todoist_event.task || task_attributes.fetch(:todoist_description).match?(Task::TODOIST_DESCRIPTION_DIVIDER)
              create_task(todoist_event, task_attributes)
            end
            return
          when "item:updated"
            # If there's no task with the Todoist ID yet, the todo's project was changed to the relevant project.
            case
            when todoist_event.task
              todoist_event.task.update!(**task_attributes)
            when task_attributes.fetch(:todoist_description).match?(Task::TODOIST_DESCRIPTION_DIVIDER)
              raise Error, "Todoist event doesn't have a task but it seems like it was created in our CMS."
            else
              create_task(todoist_event, task_attributes)
            end
            return
          when "item:deleted"
            # Three scenarios:
            # 1. The task was deleted in our CMS -> `todoist_event.task` is nil.
            # 2. The task was deleted in Todoist -> delete in our CMS.
            # 3. The task was reassigned in our CMS -> don't delete it if it has a new responsible.
            if todoist_event.task&.responsible == todoist_event.admin_user
              todoist_event.task.destroy!
            end
            return
          end

          # If there's no task with the Todoist ID and the todo was added recently,
          # it might be a race condition. Let's wait a bit and try again.
          unless todoist_event.task
            if todoist_event.added_recently?
              self.class.call_in 5.seconds, todoist_event
              return
            end
            raise Error, "Todoist event doesn't have a task but was not added recently."
          end

          case todoist_event.kind
          when "item:completed"
            todoist_event.task.done!
          when "item:uncompleted"
            todoist_event.task.undone!
          else raise Error, "Unexpected kind: #{todoist_event.kind}"
          end
        end
    end
  end
end
