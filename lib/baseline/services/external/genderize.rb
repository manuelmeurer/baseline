# frozen_string_literal: true

module Baseline
  module External
    class Genderize < ::External::Base
      BASE_URL = "https://api.genderize.io".freeze

      add_action :get_gender, run_unless_prod: true do |name|
        cache_key = [
          self.class.to_s.parameterize,
          __method__,
          name
        ]

        Rails.cache.fetch cache_key do
          request(
            :get, "",
            params: {
              name:,
              country_id: :DE
            }
          ).fetch(:gender)
        end
      end
    end
  end
end
