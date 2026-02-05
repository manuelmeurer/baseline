# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module ContactRequest
        def fields
          field :id
          field :kind
          field :status, as: :badge, options: { warning: :pending, danger: :ignored, success: :messaged_except_created }
          actions_field do
            [
              render_avo_button(
                avo.new_resources_contact_request_message_path(recipient_gid: record.to_gid.to_s),
                icon:  "heroicons/outline/envelope",
                title: "Message"
              ),
              unless record.ignored?
                render_avo_button \
                  Baseline::Avo::Actions::Ignore,
                  icon:  "heroicons/outline/eye-slash",
                  title: "Ignore"
              end
            ]
          end
          field :name
          field :email
          field :phone
          field :locale
          field :company
          field :message, show_on: :all # By default, Avo hides text fields on index
          field :details
          field :ignored_at, only_on: :display
          timestamp_fields
          field :messages
          field :tasks
        end

        def actions
          unless record&.ignored?
            action Avo::Actions::Ignore
          end
          unless record&.unignored?
            action Avo::Actions::Unignore
          end
        end
      end
    end
  end
end
