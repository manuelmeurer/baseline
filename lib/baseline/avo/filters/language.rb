# frozen_string_literal: true

module Baseline
  module Avo
    module Filters
      class Language < ::Avo::Filters::SelectFilter
        self.name = "Language"

        def apply(request, query, value)
          query.where(locale: value)
        end

        def options
          I18n
            .available_locales
            .map { ::Language.new locale: _1 }
            .index_by(&:locale)
            .transform_values(&:name)
        end
      end
    end
  end
end
