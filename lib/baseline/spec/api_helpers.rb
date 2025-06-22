# frozen_string_literal: true

module Baseline
  module Spec
    module APIHelpers
      def response_json
        JSON.parse(response.body, symbolize_names: true)
      end
    end
  end
end
