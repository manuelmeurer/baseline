# frozen_string_literal: true

Rails.configuration.app_stimulus_namespaces =
  @namespaces.if(Array) {
    _1.index_with {
      [it, :shared]
    }
  }

Rails.configuration.stimulus_app_namespaces =
  Rails
    .configuration
    .app_stimulus_namespaces
    .values
    .flatten
    .uniq
    .index_with { |stimulus_namespace|
      Rails
        .configuration
        .app_stimulus_namespaces
        .select { _2.include? stimulus_namespace }
        .keys
    }
