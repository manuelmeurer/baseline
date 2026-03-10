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
          if related_name = params["related_name"]
            # When accessed via an association (e.g. Event -> applications), look up the
            # association to get the actual class (EventApplication, not Application).
            parent_resource = params["resource_name"].classify.constantize
            parent_resource.reflect_on_association(related_name).klass
          else
            params.fetch("controller").delete_prefix("avo/").classify.constantize
          end
        end
      end
    end
  end
end
