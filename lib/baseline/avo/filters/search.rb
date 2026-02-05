# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      class Search < ::Avo::Filters::TextFilter
        self.name = "Search"

        def apply(request, query, value)
          query.if(value.presence) {
            _1.klass.search(_1)
          }
        end
      end
    end
  end
end
