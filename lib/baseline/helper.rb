# frozen_string_literal: true

module Baseline
  module Helper
    def common_stimco
      [
        controller_name,
        :common
      ].join(" ")
        .then { stimco _1, to_h: false }
    end

    def action_stimco
      controller_and_normalized_action_name
        .join(" ")
        .then { stimco _1, to_h: false }
    end

    def resource_stimco
      return unless normalized_action_name == "show" && id = params[:id].presence

      [
        controller_name,
        id
      ].join(" ")
        .then { stimco _1, to_h: false }
    end

    def body_data
      stimcos = Rails
        .configuration
        .app_stimulus_namespaces
        .fetch(::Current.namespace)
        .map { stimco _1 }

      [
        *stimcos,
        common_stimco.to_h,
        action_stimco.to_h,
        resource_stimco&.to_h
      ].compact
        .then {
          data_merge(*_1)
        }
    end

    def alert(level, text = nil, heading: nil, icon: nil, closeable: true, hide_id: nil, css_class: nil, data: {}, &block)
      css_class = [
        "alert",
        "alert-#{level}",
        ("alert-dismissible" if closeable),
        "fade",
        "show",
        "d-none",
        css_class
      ].compact

      text = text&.html_safe || capture_haml(&block)

      if text.blank?
        raise "No text set for alert."
      end

      heading = if heading
        [
          icon&.then { component :icon, _1, version: :solid, class: "me-1" },
          heading
        ].compact
          .join(" ")
          .html_safe
          .then { tag.h4 _1, class: "alert-heading" }
      end

      icon_and_text = if icon && !heading
        component(:icon, icon, version: :solid, size: "lg", class: "me-3")
          .concat(tag.div(text)) # Wrap text in <div> to ensure that "display: flex" works as expected.
          .then { tag.div _1, class: "d-flex align-items-center" }
      end

      close_button = if closeable
        tag.button(type: "button", class: "btn-close", data: { bs_dismiss: "alert" })
      end

      data = data_merge(data, stimco(:alert, hide_id:))

      [
        close_button,
        heading,
        icon_and_text || text
      ].compact
        .join("\n")
        .html_safe
        .then { tag.div _1, class: css_class, data: }
    end

    def flashes
      flash
        .map do |level, message|
          level = { notice: "success", alert: "danger" }[level.to_sym] || level
          alert level, message
        end
        .compact
        .then { safe_join _1, "\n" }
    end

    def async_turbo_frame(name, loading_message: NOT_SET, loading_content: nil, **attributes, &block)
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

      if specific_turbo_frame_request?(name) || ActiveRecord::Type::Boolean.new.cast(params[:_load_frame])
        turbo_frame_tag name, &block
      else
        turbo_frame_tag name, **attributes do
          loading_content || begin
            loading_params =
              loading_message == NOT_SET ?
              {} :
              { message: loading_message }
            component :loading, **loading_params
          end
        end
      end
    end

    def turbo_data(method:       :patch,
                   confirm:      true,
                   submits_with: true,
                   frame:        ("modal" if ::Current.try(:modal_request)))

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

      Rails.cache.fetch(cache_key, force: Rails.env.development?) do
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
        tag.meta name:, content: content.if(Hash, &:to_json)
      end.then {
        safe_join _1, "\n"
      }
    end

    def controller_and_normalized_action_name
      [
        controller_name,
        normalized_action_name
      ]
    end

    def body_css_class
      [
        *controller_and_normalized_action_name,
        params[:id]
      ].compact
    end

    def data_merge(*datas)
      return {} unless datas = datas.compact_blank.map(&:to_h).presence

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
            if values.any? { !_1.is_a?(String) && !_1.is_a?(Symbol) }
              raise "Don't know how to merge multiple data values that are not strings or symbols: #{values}"
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

    def component(name, *, **, &)
      component = name
        .to_s
        .split("/")
        .tap { _1.last << "_component" }
        .inject(Baseline) {
          _1.const_get(_2.camelize)
        }

      render component.new(*, **), &
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
        scope:   [::Current.namespace, :human_attribute_names, klass.to_s.underscore],
        default: human_attribute_name
    end

    def md_to_html(...)
      Converters::MarkdownToHTML.call(...)
    end

    def section(id = nil, css_class: nil, container_css_class: nil, container: false, i18n_scope: action_i18n_scope, &block)
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
          new_container_css_class = [
            :container,
            (container unless container == true)
          ].compact
            .join("-")
          container_css_class = Array(container_css_class) << new_container_css_class
          tag.div class: container_css_class do
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

    def plausible_javascript_tag
      return unless
        Rails.env.production? &&
        ::Current.namespace != :admin

      javascript_include_tag "/qwerty/js/script.js",
        defer: true,
        data: {
          domain: request.host,
          api:    "/qwerty/api/event"
        }
    end

    def icon_links
      [
        tag.link(
          rel:   "icon",
          href:  "/favicon.ico",
          sizes: "32x32"
        ),
        tag.link(
          rel:  "icon",
          href: namespaced_or_default_asset("icons/icon.svg").url,
          type: "image/svg+xml"
        ),
        tag.link(
          rel:  "apple-touch-icon",
          href: namespaced_or_default_asset("icons/apple-touch-icon.png").url
        )
      ]
    end

    def manifest_link_if_allowed
      if controller_path
        .split("/")
        .first
        .camelize
        .constantize
        .const_get(:EssentialsController)
        .new
        .render_manifest?

        tag.link \
          rel:  "manifest",
          href: url_for([::Current.namespace, :manifest, format: :json])
      end
    end

    def og_data_tags(prefix = "og", data = og_data)
      data.map do |key, value|
        if value.is_a?(Hash)
          new_prefix = [
            (prefix unless prefix == "og"),
            key
          ].compact
            .join(":")
          public_send __method__, new_prefix, value
        else
          property = [
            prefix,
            key
          ].compact
            .join(":")
          Array(value).map do |content|
            tag.meta \
              property:,
              content:
          end
        end
      end
    end

    def stylesheets
      @stylesheets ||= Hash.new
    end

    def add_stylesheet(stylesheet, name, disabled: false, **options)
      if !stylesheet.match?(URLFormatValidator.regex) &&
        prefix = javascript_path(name)[%r{.+@\d+(\.[^/]+)*/}, 0]

        stylesheet = File.join(prefix, stylesheet)
      end

      if disabled && !options.key?(:preload_links_header)
        options[:preload_links_header] = false
      end

      unless options.key?(:integrity)
        options[:integrity] = true
        if options.key?(:crossorigin) && options[:crossorigin] != "anonymous"
          raise "If integrity is set to true, crossorigin must be 'anonymous'."
        end
        options[:crossorigin] = "anonymous"
      end

      stylesheets[stylesheet] = {
        name:,
        disabled:,
        options:
      }
    end

    def javascripts
      @javascripts ||= Set.new
    end

    def add_javascript(javascript)
      javascripts << javascript
    end

    def head_tags
      @head_tags ||= Set.new
    end

    def add_head_tag(tag)
      head_tags << tag
    end

    def all_head_tags
      stylesheet_tags      = []
      disabled_stylesheets = {}
      stylesheets.each do |url, params|
        name, disabled, options = params.fetch_values(:name, :disabled, :options)
        tag = stylesheet_link_tag(url, **options)

        if disabled
          disabled_stylesheets[name] ||= []
          disabled_stylesheets[name] << tag
        else
          stylesheet_tags << tag
        end
      end

      safe_join [
        head_tags.to_a,
        csrf_meta_tags,
        csp_meta_tag,
        javascript_importmap_tags(
          ::Current.namespace.to_s,
          importmap: Rails.application.namespace_importmap
        ),
        javascripts.map { javascript_import_module_tag _1 },
        meta_tags(
          action_name:,
          disabled_stylesheets:,
          revision:    Rails.configuration.revision,
          sentry_user: Sentry.get_current_scope.user,
          rails_env:   Rails.env
        ),
        og_data_tags,
        icon_links,
        manifest_link_if_allowed,
        plausible_javascript_tag,
        stylesheet_link_tag(::Current.namespace.to_s, integrity: true, crossorigin: "anonymous", data: { turbo_track: "reload" }),
        stylesheet_tags,
        turbo_refresh_method_tag(:morph)
      ], "\n"
    end

    def javascript_path(name)
      Rails
        .application
        .importmap
        .packages
        .fetch(name.to_s)
        .path
    end

    def other_locale_url
      params
        .permit!
        .merge(locale: I18n.other_locale.to_s)
        .then {
          url_for _1
        }
    end

    def normalize_url(url)
      case url
      when Array
        unless url.last.is_a?(Hash)
          url << {}
        end
        url.last[:only_path] = false
        url = url_for(url)
      when Hash
        url = url_for(**url, only_path: false)
      when String
        url
      else raise "Unexpected URL: #{url.class}"
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

            tag.a(link_text, **html.merge(href:)) +
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

      def credential_meta_tags(*names)
        names
          .index_with { Rails.application.env_credentials.dig(*_1.to_s.split(".")) }
          .then { meta_tags _1 }
      end

      def modal_default_size = "lg"

      def set_color_mode
        tag.script do
          <<~JS.html_safe
            document.documentElement.setAttribute(
              "data-bs-theme",
              (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
            )
          JS
        end
      end

      def local_time_i18n(locale)
        I18n.with_locale locale do
          {
            date: {
              dayNames:       t(:day_names, scope: :date),
              abbrDayNames:   t(:abbr_day_names, scope: :date),
              monthNames:     t(:month_names, scope: :date)[1..-1],
              abbrMonthNames: t(:abbr_month_names, scope: :date)[1..-1],
              yesterday:      t(:yesterday),
              today:          t(:today),
              tomorrow:       t(:tomorrow),
              on:             "am {date}",
              formats: {
                default:  "%e. %B %Y",
                thisYear: "%e. %B"
              }
            },
            time: {
              am:         "am",
              pm:         "pm",
              singular:   "eine {time}",
              singularAn: "eine {time}",
              elapsed:    "vor {time}",
              second:     "Sekunde",
              seconds:    "Sekunden",
              minute:     "Minute",
              minutes:    "Minuten",
              hour:       "Stunde",
              hours:      "Stunden",
              formats: {
                default:     "%l:%M%P",
                default_24h: "%-H:%M"
              }
            },
            datetime: {
              at: "{date} um {time}",
              on_at: "am {date} um {time}",
              formats: {
                default: "%e. %B %Y um %l:%M%P %Z",
                default_24h: "%e. %B %Y um %-H:%M %Z"
              }
            }
          }
        end
      end

      def password_hint
        return unless validator = User.validators_on(:password).grep(ActiveRecord::Validations::LengthValidator).first

        validator
          .options
          .slice(:minimum, :maximum)
          .map do |validation, value|
            t validation, scope: :password_hint, value:
          end.join(", ")
      end
  end
end
