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
          # Normally, the params look like this:
          # { "controller" => "avo/tasks", ... }
          # If the resource is accessed via a association though, they look like this:
          # { "controller" => "avo/associations", "related_name" => "tasks", ... }
          model_class = params.fetch("related_name") {
            params.fetch("controller").delete_prefix("avo/")
          }.classify.constantize

          model_class
            .statuses
            .index_with(&:titleize)
        end
      end
    end
  end
end
