# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      module EnumHelpers
        extend ActiveSupport::Concern

        included do
          include SelectHelpers
        end

        def options
          model_class
            .public_send(attribute.pluralize)
            .transform_values {
              model_class.human_enum_name(attribute, _1)
            }
        end
      end
    end
  end
end
