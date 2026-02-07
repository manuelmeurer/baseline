# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module AdminUser
        def fields
          field :id
          field :name, as: :text
          field :photo, delegated_model_class: "User"
          field :email
          field :alternate_emails
          tasks_field
          timestamp_fields
        end
      end
    end
  end
end
