# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module ContactRequest
        def fields
          field :id
          field :kind
          field :name
          field :email
          field :phone
          field :locale
          field :company
          field :message
          field :message, only_on: :index do
            if record.message.present?
              ActionView::Base
                .full_sanitizer
                .sanitize(record.message)
                .truncate(30)
            else
              "-"
            end
          end
          field :details
          field :ignored_at, only_on: :display
          timestamp_fields
          field :messages
          field :tasks
        end

        def filters
          super
          filter Avo::Filters::Status
        end

        def actions
          unless record&.ignored?
            action Ignore
          end
          unless record&.unignored?
            action Unignore
          end
        end

        class Ignore < ::Avo::BaseAction
          def handle(query:, **)
            process(
              query,
              condition:       -> { !_1.ignored? },
              success_message: "ignored successfully.",
              error_message:   "already ignored."
            ) {
              _1.ignored!
            }
          end
        end

        class Unignore < ::Avo::BaseAction
          def handle(query:, **)
            process(
              query,
              condition:       -> { _1.ignored? },
              success_message: "unignored successfully.",
              error_message:   "already unignored."
            ) {
              _1.unignored!
            }
          end
        end
      end
    end
  end
end
