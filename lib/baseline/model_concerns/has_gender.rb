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
          validate: true
      }
    end
  end
end
