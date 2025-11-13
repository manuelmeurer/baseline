# frozen_string_literal: true

module Baseline
  module HasGender
    extend ActiveSupport::Concern

    included do
      %i[
        male
        female
      ].then {
        enum :gender, _1,
          validate: { allow_nil: true }
      }

      before_validation :set_gender,
        on: :create,
        if: -> {
          self.class.validators_on(:gender).any?(ActiveRecord::Validations::PresenceValidator)
        }
    end

    def set_gender
      if gender.nil? && try(:first_name).present?
        require "baseline/services/external/genderize"
        self.gender = Baseline::External::Genderize.get_gender(first_name) || "male"
      end
    end
  end
end
