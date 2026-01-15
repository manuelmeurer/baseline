# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Task
        def fields
          field :id
          field :title
          field :details
          field :done?, only_on: :display
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
            action Done
          end
          unless record&.undone?
            action Undone
          end
        end

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
    end
  end
end
