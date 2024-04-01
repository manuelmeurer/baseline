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

    def async_turbo_frame(name, loading_message: Current.missing_value, **attributes, &block)
      # If a ActiveRecord record is passed to `turbo_frame_tag`,
      # `dom_id` is called to determine its DOM ID.
      # This exposes the record ID, which is not desirable if the record has a slug.
      if name.is_a?(ActiveRecord::Base) && name.respond_to?(:slug)
        name = [name.class.to_s.underscore, name.slug].join("_")
      end

      unless attributes.key?(:src)
        raise "async_turbo_frame needs a `src` attribute."
      end

      attributes[:refresh] ||= "morph"

      if specific_turbo_frame_request?(name)
        turbo_frame_tag name, &block
      else
        turbo_frame_tag name, **attributes do
          loading_params = loading_message == Current.missing_value ?
                           {} :
                           { message: loading_message }
          render "shared/loading", **loading_params
        end
      end
    end

    def inline_svg(filename, **options)
      unless File.extname(filename) == ".svg"
        raise "Must be a SVG file: #{filename}"
      end

      cache_key = [
        :inline_svg,
        Rails.configuration.revision,
        filename,
        options.sort.to_json.then { ActiveSupport::Digest.hexdigest _1 }
      ].join(":")

      Rails.cache.fetch cache_key do
        unless path = Rails.application.assets.load_path.find(filename)
          raise "Could not find asset: #{path}"
        end

        content = path.content

        unless css_class = options[:class].presence
          return content
        end

        Nokogiri::XML::Document
          .parse(content)
          .at_css("svg")
          .tap {
            _1["class"] = [
              *_1["class"]&.split(" "),
              css_class
            ].compact
             .uniq
             .join(" ")
          }.to_s
      end.html_safe
    end
  end
end
