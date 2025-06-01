# frozen_string_literal: true

class SitemapGenerator::Interpreter
  def add(link, options = {})
    if link.is_a?(Array)
      link = Rails.application.routes.url_helpers.url_for([*link, only_path: true])
    end
    @linkset.add link, options
  end

  def add_with_alternates(url_parts, url_params: [], params: {})
    I18n.available_locales.each do |locale|
      alternates = I18n.available_locales.map do |alternate_locale|
        alternate_url_method = [*url_parts, alternate_locale, :url].join("_")
        {
          href: public_send(alternate_url_method, *url_params),
          lang: alternate_locale
        }
      end
      url_method = [*url_parts, locale, :path].join("_")
      add \
        public_send(url_method, *url_params),
        params.merge(alternates:)
    end
  end
end
