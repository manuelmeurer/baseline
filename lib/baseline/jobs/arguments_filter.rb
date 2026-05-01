# frozen_string_literal: true

class Baseline::Jobs::ArgumentsFilter
  def initialize(keys)
    @keys = Array(keys).map(&:to_s)
  end

  def apply_to(value)
    case value
    when Hash
      value.to_h do |key, nested_value|
        [
          key,
          filter_key?(key) ? "[FILTERED]" : apply_to(nested_value)
        ]
      end
    when Array
      value.map { apply_to(_1) }
    else
      value
    end
  end

  private

    attr_reader :keys

    def filter_key?(key) = keys.include?(key.to_s)
end
