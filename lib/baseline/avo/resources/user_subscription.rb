# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module UserSubscription
        extend ActiveSupport::Concern

        included do
          self.visible_on_sidebar = false
        end

        def fields
          field :subscription
          tasks_field
          timestamp_fields
        end
      end
    end
  end
end
