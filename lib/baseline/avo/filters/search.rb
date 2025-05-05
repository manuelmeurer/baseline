# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      class Search < Avo::Filters::TextFilter
        self.name = "Search"

        def apply(request, query, value)
          query
            .klass
            .search(value)
        end
      end
    end
  end
end
