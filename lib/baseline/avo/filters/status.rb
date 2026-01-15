# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      class Status < ::Avo::Filters::SelectFilter
        self.name = "Status"

        def apply(request, query, value)
          query.if(value) {
            _1.public_send(_2)
          }
        end

        def options
          # Hacky way to get the current model class.
          model_class = params.fetch("controller").delete_prefix("avo/").classify.constantize

          model_class
            .statuses
            .index_with(&:titleize)
        end
      end
    end
  end
end
