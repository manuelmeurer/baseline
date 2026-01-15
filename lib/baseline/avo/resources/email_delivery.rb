# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module EmailDelivery
        extend ActiveSupport::Concern

        included do
          self.visible_on_sidebar = false
        end

        def fields
          field :id
          field :subject
          field :sections_md, as: :textarea
          field :recipients, only_on: :display
          field :cc_recipients, only_on: :display
          field :bcc_recipients, only_on: :display
          field :rejected_emails, only_on: :display
          field :bounced_emails, only_on: :display
          field :html_content, only_on: :display
          field :text_content, only_on: :display
          field :scheduled_at
          field :sent_at, only_on: :display
          field :message_id, only_on: :display
          field :admin_user, only_on: :display
          field :deliverable
          timestamp_fields
          field :tasks
          field :sections
        end
      end
    end
  end
end
