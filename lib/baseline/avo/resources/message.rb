# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Message
        def fields
          field :id
          field :kind
          field :recipient, readonly: true
          field :email_delivery, only_on: :show
          field :email_delivery_subject, as: :text, only_on: :new
          field :email_delivery_sections_md, as: :textarea, only_on: :new
          field :messageable, readonly: true
          timestamp_fields
          field :tasks
        end
      end
    end
  end
end
