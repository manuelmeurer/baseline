# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      module SelectHelpers
        extend ActiveSupport::Concern

        included do
          mattr_accessor :attribute, default: self.to_s.demodulize.underscore
          self.name = attribute.titleize
        end

        def apply(request, query, value)
          query.if(value) {
            _1.where(attribute => _2)
          }
        end

        def model_class
          # Hacky way to get the current model class.
          # Normally, the params look like this:
          # { "controller" => "avo/tasks", ... }
          # If the resource is accessed via a association though, they look like this:
          # { "controller" => "avo/associations", "related_name" => "tasks", ... }
          params.fetch("related_name") {
            params.fetch("controller").delete_prefix("avo/")
          }.classify.constantize
        end
      end
    end
  end
end
