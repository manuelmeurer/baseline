module Baseline
  module Helper
    def async_turbo_frame(name, **attributes, &block)
      # If a ActiveRecord record is passed to `turbo_frame_tag`,
      # `dom_id` is called to determine its DOM ID.
      # This exposes the record ID, which is not desirable if the record has a slug.
      if name.is_a?(ActiveRecord::Base) && name.respond_to?(:slug)
        name = [name.class.to_s.underscore, name.slug].join("_")
      end

      unless url = attributes[:src]
        raise "async_turbo_frame needs a `src` attribute."
      end

      uris = [
        url_for(url),
        request.fullpath
      ].map { Addressable::URI.parse _1 }
      uris_match = %i(path query_values).all? { uris.map(&_1).uniq.size == 1 }

      if uris_match
        turbo_frame_tag name, &block
      else
        turbo_frame_tag name, **attributes do
          render "shared/loading"
        end
      end
    end
  end
end
