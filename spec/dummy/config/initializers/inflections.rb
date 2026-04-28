# frozen_string_literal: true

ActiveSupport::Inflector.inflections :en do
  %w[
    API
    CMS
    MJML
    URL
  ].each(&_1.method(:acronym))
end
