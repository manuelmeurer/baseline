# frozen_string_literal: true

module Baseline
  module External
    class Genderize < ::External::Base
      BASE_URL = "https://api.genderize.io".freeze

      add_action :get_gender, return_unless_prod: "male" do |name, locale = :de|
        cache_key = [
          self.class.to_s,
          :get_gender,
          locale,
          name
        ]

        Rails.cache.fetch cache_key do
          request(
            :get, "",
            params: {
              name:,
              country_id: locale.upcase
            }
          ).fetch(:gender)
        end
      end
    end
  end
end
