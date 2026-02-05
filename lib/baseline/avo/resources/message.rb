# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Message
        def fields
          field :id
          field :kind
          field :sent_at, as: :date_time, readonly: true
          field :recipient, readonly: true
          field :email_delivery, only_on: :show
          field :email_delivery_subject, as: :text, only_on: :new
          field :email_delivery_sections_md, as: :textarea, only_on: :new
          field :messageable, readonly: true, can_create: false

          # This field will be hidden if the message does not have a `create_follow_up_task` attribute.
          field :create_follow_up_task, as: :boolean, only_on: :new

          timestamp_fields
          field :tasks
        end

        def filters
          super
          filter Sent
        end

        class Sent < ::Avo::Filters::SelectFilter
          self.name = "Sent?"

          def apply(request, query, values)
            ActiveRecord::Type::Boolean.new.cast(values) ?
              query.sent :
              query.unsent
          end

          def options
            {
              true  => "Sent",
              false => "Unsent"
            }
          end
        end
      end
    end
  end
end
