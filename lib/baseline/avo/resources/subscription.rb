# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Subscription
        extend ActiveSupport::Concern

        included do
          self.visible_on_sidebar = false
          self.find_record_method = -> {
            query.find_by!(identifier: id)
          }
        end

        def fields
          field :id
          field :identifier
          tasks_field
          timestamp_fields
        end
      end
    end
  end
end
