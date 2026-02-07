# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module City
        def fields
          field :id
          field :name
          field :slug
          field :country
          field :state
          field :latitude, only_on: :show
          field :longitude, only_on: :show
          tasks_field
          timestamp_fields
          field :locations
        end
      end
    end
  end
end
