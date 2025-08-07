# frozen_string_literal: true

module Baseline
  class Inflector < Zeitwerk::GemInflector
    ACRONYMS = %w[API HTML ID PDF URL VAT].freeze

    def camelize(...)
      ACRONYMS.inject(super) {
        regex = %r{
          (?<=\A|[a-z])
          #{_2.capitalize}
          (?=\z|[A-Z])
        }x
        _1.gsub(regex, _2)
      }
    end
  end
end
