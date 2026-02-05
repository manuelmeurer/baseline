# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Task
        def fields
          field :id
          field :status, as: :badge, options: { success: :done, warning: :undone }
          actions_field do
            if record.done?
              render_avo_button \
                Actions::Undone,
                icon:  "heroicons/outline/minus-circle",
                title: "Mark as undone"
            else
              render_avo_button \
                Actions::Done,
                icon:  "heroicons/outline/check-circle",
                title: "Mark as done"
            end
          end
          field :title
          field :details
          field :due_on
          field :identifier, only_on: :display
          field :priority
          field :taskable
          field :responsible
          field :creator, only_on: :display
          timestamp_fields
        end

        def actions
          unless record&.done?
            action Actions::Done
          end
          unless record&.undone?
            action Actions::Undone
          end
        end

        def filters
          super
          filter Filters::DueOn
        end

        module Actions
          class Done < ::Avo::BaseAction
            def handle(query:, **)
              process(
                query,
                condition:       -> { !_1.done? },
                success_message: "done successfully.",
                error_message:   "already done."
              ) {
                _1.done!
              }
            end
          end

          class Undone < ::Avo::BaseAction
            def handle(query:, **)
              process(
                query,
                condition:       -> { _1.done? },
                success_message: "undone successfully.",
                error_message:   "already undone."
              ) {
                _1.undone!
              }
            end
          end
        end

        module Filters
          class DueOn < ::Avo::Filters::SelectFilter
            self.name = "Due on"

            def apply(request, query, value)
              query.if(value) {
                _1.public_send(_2)
              }
            end

            def options
              {
                due_before: "Due today or overdue",
                overdue:    "Overdue",
                due_today:  "Due today",
                due_after:  "Upcoming"
              }
            end
          end
        end
      end
    end
  end
end
