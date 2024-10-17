# frozen_string_literal: true

module Baseline
  class StimulusController
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :values, default: {}
    attribute :outlets, default: {}
    attribute :name

    def name=(value)
      value
        .to_s
        .downcase
        .gsub(/[^a-z0-9]/, "-")
        .then { super _1 }
    end

    def to_h(**more_values)
      {
        controller: name,
        **outlets.transform_keys { :"#{name}-#{_1.to_s.dasherize}-outlet" },
        **values.merge(more_values).transform_keys { :"#{name}-#{_1.to_s.dasherize}-value" }
      }
    end

    def target(target_name)
      { "#{name}-target": target_name.to_s.camelize(:lower) }
    end

    def action(action_name = nil, **params)
      unless action_name
        event, action_name = params.shift
      end

      value = [name, action_name.to_s.camelize(:lower)]
        .join("#")
        .if(event) { [_2, _1].join "->" }

      {
        action: value,
        **params.transform_keys { :"#{name}-#{_1.to_s.dasherize}-param" }
      }
    end
  end
end
