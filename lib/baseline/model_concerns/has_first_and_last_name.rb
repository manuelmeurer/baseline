# frozen_string_literal: true

module Baseline
  module HasFirstAndLastName
    extend ActiveSupport::Concern

    def name=(name)
      return if name.blank?

      name_parts = name
        .strip
        .sub(/\Adr\.?\s+/i, "")
        .then {
          _1.include?(",") ?
            _1.split(/\s*,\s*/, 2).reverse :
            _1.split(/\s+/, 2)
        }

      if name_parts.first.present?
        self.first_name = name_parts.first
      end
      if name_parts.last.present?
        self.last_name = name_parts.last
      end
    end

    def name
      [first_name, last_name]
        .compact_blank
        .join(" ")
    end
  end
end
