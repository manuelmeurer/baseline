# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      class Status < ::Avo::Filters::SelectFilter
        include SelectHelpers

        def apply(request, query, value)
          query.if(value) {
            _1.public_send(_2)
          }
        end

        def options
          model_class
            .statuses
            .index_with(&:titleize)
        end
      end
    end
  end
end
