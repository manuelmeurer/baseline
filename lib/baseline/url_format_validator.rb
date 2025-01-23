# frozen_string_literal: true

validator = Class.new(ActiveModel::EachValidator) do
  REGEX = %r(\Ahttps?://).freeze

  def validate_each(record, attribute, value)
    valid =
      record.class.columns_hash.fetch(attribute.to_s).array ?
      value.all? { _1.match?(REGEX) } :
      (options[:allow_blank] && value.blank?) || value.match?(REGEX)

    unless valid
      record.errors.add attribute,
        message: options.fetch(:message, "must start with http:// or https://")
    end
  end
end

# Set the class name dynamically, since "URL" might be defined as an acronym in the Rails app.
Object.const_set \
  "url_format_validator".classify,
  validator
