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
        **outlets.transform_keys { :"#{name}-#{_1.dasherize}-outlet" },
        **values.merge(more_values).transform_keys { :"#{name}-#{_1.dasherize}-value" }
      }
    end

    def target(target_name)
      { "#{name}-target": target_name.camelize(:lower) }
    end

    def action(action_name = nil, option: nil, **params)
      unless action_name
        event, action_name = params.shift
      end

      value = [name, action_name.camelize(:lower)]
        .join("#")
        .if(event) { [_2, _1].join "->" }
        .if(option) { _1 << ":#{option}" }

      {
        action: value,
        **params.transform_keys { :"#{name}-#{_1.dasherize}-param" }
      }
    end
  end
end
