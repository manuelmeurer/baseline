# frozen_string_literal: true

module Baseline
  class URLFormatValidator < ActiveModel::EachValidator
    def self.regex = %r{\Ahttps?://}.freeze

    def validate_each(record, attribute, value)
      valid =
        record.class.schema_columns.fetch(attribute)[:array] ? # Only works for Postgres
        value.all? { _1.match?(self.class.regex) } :
        (options[:allow_blank] && value.blank?) || value.match?(self.class.regex)

      unless valid
        record.errors.add attribute,
          message: options.fetch(:message, "must start with http:// or https://")
      end
    end
  end
end
