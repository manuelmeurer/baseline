module Baseline
  module Helper
    def page_classes
      [
        controller.controller_name,
        { "create" => "new", "update" => "edit" }.fetch(controller.action_name, controller.action_name)
      ].join(" ")
    end

    def alert(level, text = nil, heading: nil, closeable: true, hide_id: nil, css_class: nil, data: {}, &block)
      classes = [
        "alert",
        "alert-#{level}",
        ("alert-dismissible" if closeable),
        "fade",
        "show",
        css_class
      ].compact

      tag.div class: classes, data: data do
        if closeable
          concat tag.button(type: "button", class: "btn-close", data: { bs_dismiss: "alert" })
        end
        if heading
          concat tag.h4(heading, class: "alert-heading")
        end
        concat text&.html_safe || capture_haml(&block)
      end
    end

    def flashes
      flash
        .map do |level, message|
          level = { notice: "success", alert: "danger" }[level.to_sym] || level
          alert level, message
        end
        .compact
        .join("\n")
        .html_safe
    end

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
