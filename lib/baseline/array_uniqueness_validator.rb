# frozen_string_literal: true

module Baseline
  class ArrayUniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      return if value.blank?

      duplicates = value
        .tally
        .select { _2 > 1 }
        .keys

      if duplicates.any?
        record.errors.add attribute,
          message: options.fetch(:message, "contain duplicates: #{duplicates.join(", ")}")
      end
    end
  end
end
