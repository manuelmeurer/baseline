# frozen_string_literal: true

module Baseline
  module Avo
    module Resources
      module Location
        def fields
          field :id
          field :name
          field :address
          field :zip
          field :city, searchable: false
          field :state
          field :country
          field :url
          field :locationable, readonly: true, can_create: false
          field :latitude, only_on: :show
          field :longitude, only_on: :show
          tasks_field
          timestamp_fields
        end
      end
    end
  end
end
