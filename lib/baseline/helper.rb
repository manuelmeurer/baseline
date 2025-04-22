# frozen_string_literal: true

module Baseline
  module Helper
    prepend MemoWise

    CLOUDINARY_VERSIONS = {
      xs:  50,
      sm: 100,
      md: 250,
      lg: 500
    }.inject({}) do |versions, (key, size)|
      {
        "#{key}_fit": {
          crop: :fit
        },
        "#{key}_fit_gray": {
          crop:   :fit,
          effect: :grayscale
        },
        "#{key}_fit_rounded": {
          crop:   :fit,
          radius: 20
        },
        "#{key}_thumb": {
          crop:    :thumb,
          gravity: :face
        },
        "#{key}_thumb_rounded": {
          crop:    :thumb,
          gravity: :face,
          radius:  20
        }
      }.transform_values {
        _1.merge \
          quality:      :auto,
          fetch_format: :auto,
          width:        size,
          height:       size
      }.then {
        _1.merge(
          _1.transform_keys   { |key| :"wide_#{key}" }
            .transform_values { |value| value.merge(width: value.fetch(:width) * 2) }
        )
      }.then {
        versions.merge _1
      }
    end.freeze

    ICON_VERSIONS = %i(
      solid
      regular
      light
      duotone
      thin
      brands
    ).freeze

    %i(tag path).each do |suffix|
      define_method :"attachment_image_#{suffix}" do |attached, version, **options|
        unless attached.attached?
          if Rails.env.production?
            raise "Attached is not attached."
          else
            return
          end
        end

        options = CLOUDINARY_VERSIONS
          .fetch(version)
          .merge(options)

        # Don't compare `attached.service.class` directly since the
        # ActiveStorage::Service::* subclasses don't exist if they are not used.
        case service = attached.service.class.to_s.demodulize
        when "DiskService"
          variant = attached.variant(
            resize_to_fill: options.fetch_values(:width, :height)
          )
          public_send \
            :"image_#{suffix}",
            polymorphic_url(variant, host: Rails.application.env_credentials.host!),
            **options
        when "CloudinaryService"
          public_send \
            :"cl_image_#{suffix}",
            attached.key,
            **options
        else
          raise "Unexpected service: #{service}"
        end
          .gsub(/\s+(width|height)=['"]\d+['"]/, "")
          .html_safe
      end.then {
        memo_wise _1
      }
    end

    def icon_classes
      {
        nil => {
          accept:   "fa-circle-check",
          reject:   "fa-circle-xmark",
          add:      "fa-circle-plus",
          remove:   "fa-trash",
          edit:     "fa-pen",
          view:     "fa-eye",
          info:     "fa-circle-info",
          warning:  "fa-triangle-exclamation",
          announce: "fa-bullhorn",
          external: "fa-square-up-right",
          back:     "fa-arrow-left-long",
          forward:  "fa-arrow-right-long",
          yes:      "fa-thumbs-up",
          no:       "fa-thumbs-down"
        }
      }
    end

    def icon(identifier, scope: nil, version: :regular, size: nil, fixed_width: false, **kwargs)
      unless version.in?(ICON_VERSIONS)
        raise "#{version} is not a valid versions: #{ICON_VERSIONS.join(", ")}"
      end

      icon_class = case
        when identifier.class.in?([Symbol, Integer])
          case ic = icon_classes.fetch(scope)
          when Hash  then ic.fetch(identifier.to_sym)
          when Array then ic[identifier] or raise "#{identifier} not found in icon classes: #{ic.join(", ")}"
          else raise "Unexpected classes: #{ic.class}"
          end
        when scope
          raise "Scope should be nil if identifier is not a symbol."
        else
          "fa-#{identifier}"
        end

      tag.i \
        class: [
          "fa-#{version}",
          size&.then { "fa-#{_1}" },
          ("fa-fw" if fixed_width),
          icon_class,
          kwargs.delete(:class)
        ].compact,
        **kwargs
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
      if slug = name.try(:slug)
        name = [name.class.to_s.underscore, slug].join("_")
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
          break content
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

      datas
        .flat_map(&:keys)
        .uniq
        .index_with do |key|
          values = datas
            .select { _1.key? key }
            .map { _1.fetch key }

          if values.size == 1
            values.first
          else
            unless values.all?(String)
              raise "Don't know how to merge multiple data values that are not strings: #{values}"
            end
            values
              .compact_blank
              .join(" ")
          end
        end
    end

    def link_to_modal(name = nil, options = nil, html_options = nil, &block)
      if block
        options, html_options, name = name, options, capture(&block)
      end
      html_options ||= {}
      html_options[:data] ||= {}
      html_options[:data].merge!(
        bs_toggle: "modal",
        bs_target: "#modal",
        url:       url_for(options)
      )
      link_to name, "#", html_options
    end

    def form_field(*, **, &)
      render Baseline::FormFieldComponent.new(*, **), &
    end

    def form_classes(type:, prefix: "col")
      {
        label:            %w(md-3 lg-2),
        input:            %w(md-9 lg-10 xl-6),
        input_full_width: %w(md-9 lg-10)
      }.fetch(type)
        .map { [prefix, _1].join("-") }
    end

    def custom_human_attribute_name(klass, attribute)
      human_attribute_name = klass.human_attribute_name(attribute)

      t attribute,
        scope:   [Current.namespace, :human_attribute_names, klass.to_s.underscore],
        default: human_attribute_name
    end

    def md_to_html(...)
      Baseline::MarkdownToHTML.call(...)
    end

    def section(id = nil, css_class: nil, container: false, i18n_scope: action_i18n_scope, &block)
      if block.arity == 1
        unless id
          raise "Cannot determine I18n scope without section ID."
        end
        arg = [*i18n_scope, id.to_s.tr("-", "_")]
      end

      content = -> {
        block.call(*[arg])
      }

      tag.section id: id&.to_s&.tr("_", "-"), class: css_class do
        if container
          css_class = [
            :container,
            (container unless container == true)
          ].compact
            .join("-")
          tag.div class: css_class do
            content.call
          end
        else
          content.call
        end
      end
    end

    # Copied from https://github.com/tenderlove/rails_autolink
    def auto_link(text, link: :all, html: {}, sanitize: true, &block)
      return "".html_safe if text.blank?

      if sanitize
        text = sanitize(text, sanitize.unless(Hash, {}))
      end

      case link
      when :all
        auto_link_urls(text, html:, sanitize:, &block)
          .then { auto_link_email_addresses _1, html:, sanitize:, &block }
          .if(sanitize, &:html_safe)
      when :email_addresses
        auto_link_email_addresses(text, html:, sanitize:, &block)
          .if(sanitize, &:html_safe)
      when :urls
        auto_link_urls(text, html:, sanitize:, &block)
          .if(sanitize, &:html_safe)
      else raise "Unexpected link option: #{link}"
      end
    end

    private

      AUTO_LINK_RE = %r(
        (?: ((?:http|https|mailto|webcal|ssh|sftp|file):)// | www\.\w )
        [^\s<\u00A0"]+
      )ix
      AUTO_LINK_CRE = [/<[^>]+$/, /^[^>]*>/, /<a\b.*?>/i, /<\/a>/i]
      AUTO_EMAIL_LOCAL_RE = /[\w.!#\$%&"*\/=?^`{|}~+-]/
      AUTO_EMAIL_RE = /(?<!#{AUTO_EMAIL_LOCAL_RE})[\w.!#\$%+-]\.?#{AUTO_EMAIL_LOCAL_RE}*@[\w-]+(?:\.[\w-]+)+/
      BRACKETS = { "]" => "[", ")" => "(", "}" => "{" }
      WORD_PATTERN = '\p{Word}'

      def auto_link_urls(text, html:, sanitize:, &block)
        text.gsub(AUTO_LINK_RE) do
          scheme, href = $1, $&
          punctuation = []
          trailing_gt = ""

          if auto_linked?($`, $')
            href
          else
            # don't include trailing punctuation character as part of the URL
            while href.sub!(/[^#{WORD_PATTERN}\/\-=;]$/, "")
              punctuation.push $&
              if opening = BRACKETS[punctuation.last] and href.scan(opening).size > href.scan(punctuation.last).size
                href << punctuation.pop
                break
              end
            end

            # don't include trailing &gt; entities as part of the URL
            trailing_gt = $& if href.sub!(/&gt;$/, "")

            link_text = block ? block.call(href) : href

            unless scheme
              href = "http://#{href}"
            end

            if sanitize
              link_text = sanitize(link_text)
              href      = sanitize(href)
            end

            tag.a(link_text, **html.merge(href: href)) +
              punctuation.reverse.join("") +
              trailing_gt.html_safe
          end
        end
      end

      def auto_link_email_addresses(text, html:, sanitize:, &block)
        text.gsub(AUTO_EMAIL_RE) do
          text = $&

          if auto_linked?($`, $')
            text.html_safe
          else
            display_text = block ? block.call(text) : text

            if sanitize
              text         = sanitize(text)
              unless text == display_text
                display_text = sanitize(display_text)
              end
            end

            mail_to text, display_text, html
          end
        end
      end

      # Detects already linked context or position in the middle of a tag
      def auto_linked?(left, right)
        (left =~ AUTO_LINK_CRE[0] and right =~ AUTO_LINK_CRE[1]) or
          (left.rindex(AUTO_LINK_CRE[2]) and $' !~ AUTO_LINK_CRE[3])
      end

      def plausible_javascript_tag
        return unless Rails.env.production?

        javascript_include_tag "/qwerty/js/script.js",
          defer: true,
          data: {
            domain: request.host,
            api:    "/qwerty/api/event"
          }
      end
  end
end
