# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module AdminUser
        def fields
          field :id
          field :status, as: :badge, options: { danger: :deactivated, success: :active }
          actions_field do
            deactivate_reactivate_button
          end
          field :name, as: :text, only_on: :display
          field :first_name, as: :text, only_on: :forms
          field :last_name, as: :text, only_on: :forms
          field :photo, delegated_model_class: "User"
          field :email
          field :alternate_emails, delegated_model_class: "User"
          tasks_field
          timestamp_fields
        end
      end
    end
  end
end
