# frozen_string_literal: true

module Baseline
  module HasFullName
    def first_name = name_parts.first
    def last_name  = name_parts[1..-1]&.join(" ").presence

    private

      def name_parts = name&.split(/\s+/) || []
  end
end
