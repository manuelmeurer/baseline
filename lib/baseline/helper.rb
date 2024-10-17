# frozen_string_literal: true

module Baseline
  module Helper
    def page_classes
      [
        controller.controller_name,
        { "create" => "new", "update" => "edit" }.fetch(controller.action_name, controller.action_name)
      ].join(" ")
    end

    def alert(level, text = nil, heading: nil, icon: nil, closeable: true, hide_id: nil, css_class: nil, data: {}, &block)
      css_classes = [
        "alert",
        "alert-#{level}",
        ("alert-dismissible" if closeable),
        "fade",
        "show",
        css_class
      ].compact

      text = text&.html_safe || capture_haml(&block)

      if text.blank?
        raise "No text set for alert."
      end

      heading = if heading
        [
          icon&.then { icon _1, version: :solid, class: "me-1" },
          heading
        ].compact
          .join(" ")
          .html_safe
          .then { tag.h4 _1, class: "alert-heading" }
      end

      icon_and_text = if icon && !heading
        icon(icon, version: :solid, size: "lg", class: "me-3")
          .concat(tag.div(text)) # Wrap text in <div> to ensure that "display: flex" works as expected.
          .then { tag.div _1, class: "d-flex align-items-center" }
      end

      close_button = if closeable
        tag.button(type: "button", class: "btn-close", data: { bs_dismiss: "alert" })
      end

      [
        close_button,
        heading,
        icon_and_text || text
      ].compact
        .join("\n")
        .html_safe
        .then { tag.div _1, class: css_classes, data: data }
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

    def async_turbo_frame(name, loading_message: NULL_VALUE, loading_content: nil, **attributes, &block)
      # If a ActiveRecord record is passed to `turbo_frame_tag`,
      # `dom_id` is called to determine its DOM ID.
      # This exposes the record ID, which is not desirable if the record has a slug.
      if name.is_a?(ActiveRecord::Base) && name.respond_to?(:slug)
        name = [name.class.to_s.underscore, name.slug].join("_")
      end

      unless attributes.key?(:src)
        raise "async_turbo_frame needs a `src` attribute."
      end

      attributes = attributes.reverse_merge(
        refresh: :morph,
        loading: :lazy
      )

      if specific_turbo_frame_request?(name) || ActiveRecord::Type::Boolean.new.cast(params["_load_frame"])
        turbo_frame_tag name, &block
      else
        turbo_frame_tag name, **attributes do
          loading_content || begin
            loading_params =
              loading_message == NULL_VALUE ?
              {} :
              { message: loading_message }
            render "shared/loading", **loading_params
          end
        end
      end
    end

    def turbo_data(method:       :patch,
                   confirm:      true,
                   submits_with: true,
                   frame:        ("modal" if Current.try(:modal_request)))

      {
        turbo_method:       method,
        turbo_frame:        frame,
        turbo_confirm:      confirm.is_a?(String) ? confirm : (t(:confirm) if confirm),
        turbo_submits_with: (t :please_wait if submits_with)
      }
    end

    def external_link_attributes
      {
        target: "_blank",
        rel:    "nofollow noopener"
      }
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
          raise "Could not find asset: #{filename}"
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

    def meta_tags(data)
      data.map do |name, content|
        tag.meta name: name, content: content
      end.then {
        safe_join _1
      }
    end

    def controller_and_normalized_action_name
      [
        controller_name,
        normalized_action_name
      ]
    end

    def body_classes
      [
        *controller_and_normalized_action_name,
        params[:id]
      ].compact
        .join(" ")
    end

    def data_merge(*datas)
      datas = datas.compact_blank.map(&:to_h)
      return {} if datas.empty?

      invalids = datas.reject { _1.is_a?(Hash) }
      if invalids.any?
        raise "datas must be hashes, #{pluralize invalids.size, "invalid value"} found: #{invalids.map(&:class).join(", ")}"
      end

      controller = datas
        .map { _1[:controller] }
        .compact
        .join(" ")
        .presence

      datas
        .inject(:merge)
        .if(controller) {
          _1.merge(controller: _2)
        }
    end
  end
end
