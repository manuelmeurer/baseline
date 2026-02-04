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
          field :message, show_on: :all # By default, Avo hides text fields on index
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
