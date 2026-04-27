# frozen_string_literal: true

module Baseline
  module ApplicationControllerCore
    extend ActiveSupport::Concern

    included do
      include ApplicationAvoShared,
              I18nScopes

      if defined?(MemoWise)
        prepend MemoWise
      end

      stale_when_importmap_changes

      before_action do
        PaperTrail.request.whodunnit = -> {
          (
            ::Current.try(:admin_user) ||
            ::Current.try(:user)
          )&.then {
            _1.to_gid.to_s
          }
        }
      end

      helper_method def specific_turbo_frame_request?(name_or_resource)
        name_or_resource
          .if(ActiveRecord::Base) { helpers.dom_id(_1) }
          .then { turbo_frame_request_id == _1.to_s }
      end

      helper_method def normalized_action_name(action = Current.action_name, reverse: false)
        {
          "create" => "new",
          "update" => "edit"
        }.if(reverse, &:invert)
          .fetch(action) {
            action.delete_prefix("do_")
          }
      end

      helper_method def stimco(name, to_h: true, outlets: {}, **values)
        StimulusController
          .new(name:, values:, outlets:)
          .if(to_h, &:to_h)
      end

      helper_method def site_name
        t Current.namespace,
          scope:   :site_names,
          default: t(:name, scope: :meta)
      end

      helper_method def og_data
        locale = {
          en: :en_US
        }.fetch(I18n.locale) {
          case I18n.locale
          when /\A[a-z]{2}-[A-Z]{2}\z/
            I18n.locale.to_s.tr("-", "_")
          when /\A[a-z]{2}\z/
            I18n.locale.then { "#{_1}_#{_1.upcase}" }
          else
            raise "Unexpected locale: #{I18n.locale}"
          end
        }
        title = [
          page_meta_title,
          (site_name if add_site_name_to_page_title?)
        ].compact.join(" | ")

        image = if id = params[:id]
          Rails
            .application
            .image_assets(page_image_path)
            .keys
            .detect {
              File.basename(_1, ".*") == "og"
            }&.then {
              helpers.image_url(_1)
            }
        end

        # Assign to ivar so data can be changed.
        @og_data ||= {}
        @og_data.reverse_merge(
          image:,
          locale:,
          site_name:,
          title:,
          description: page_meta_description,
          type:        "website",
          url:         url_for(only_path: false)
        )
      end

      helper_method def set_og_data(**data)
        @og_data ||= {}
        @og_data.merge! data
      end

      helper_method def namespaced_or_default_asset(source)
        cache_key = [
          Current.namespace,
          Rails.configuration.revision,
          ActiveSupport::Digest.hexdigest(source)
        ]

        Rails.cache.fetch cache_key, force: Rails.env.development? do
          namespaced_source = File.join(Current.namespace.to_s, source)
          [
            namespaced_source,
            source
          ].lazy.map {
            Rails.application.assets.load_path.find(_1)
          }.compact.first&.then {
            {
              url:  view_context.asset_path(_1.logical_path),
              path: _1.path
            }
          } or
            raise "Asset not found: neither '#{namespaced_source}' nor '#{source}' exist"
        end.then {
          Data
            .define(:url, :path)
            .new(**_1)
        }
      end

      # Returns the given route name prefixed with `Current.namespace` when
      # rendering inside the host app, or the bare name when rendering inside
      # an isolated engine (whose routes don't share the host's namespace prefixes).
      helper_method def prefix_namespace_unless_engine(name, **opts)
        in_engine = !_routes.equal?(Rails.application.routes)
        Rails.logger.warn "prefix_namespace_unless_engine(#{name.inspect}): in_engine=#{in_engine} _routes=#{_routes.object_id} app_routes=#{Rails.application.routes.object_id}"
        prefix = Current.namespace unless in_engine
        [prefix, name, opts].compact_blank
      end

      helper_method def page_image_path(path = nil)
        return nil unless id = params[:id]

        File.join([
          Current.namespace.to_s,
          controller_name,
          id,
          path
        ].compact)
      end
    end

    class_methods do
      def _baseline_finalize
        if defined?(@_baseline_finalized)
          raise "Controller #{name} has already been finalized."
        end

        before_action prepend: true do
          Current.modal_request  = specific_turbo_frame_request?(:modal)
          Current.drawer_request = specific_turbo_frame_request?(:drawer)
          Current.namespace      = controller_path.split("/").first.to_sym
          Current.action_name    = action_name
        end

        @_baseline_finalized = true
      end

      def rate_limit_create
        rate_limit \
          to:     10,
          within: 3.minutes,
          only:   :create,
          with: -> {
            add_flash :alert, t(:generic_error)
            html_redirect_to(prefix_namespace_unless_engine(:login))
          }
      end

      def redirect_to_clean_id_or_current_slug(only: :show, ignore_missing: false, &block)
        before_action only: do
          id = params.fetch(:id)

          begin
            record = instance_exec(id, &block)
          rescue ActiveRecord::RecordNotFound => error
            cleaners = [
              -> { _1.delete_suffix(")") }
            ]
            clean_id        = nil
            clean_id_record = nil

            loop do
              unless cleaner = cleaners.shift
                break if ignore_missing
                raise error
              end

              clean_id = cleaner.call(id)
              redo if clean_id == id

              clean_id_record = suppress ActiveRecord::RecordNotFound do
                instance_exec(clean_id, &block)
              end
              break if clean_id_record
            end

            if clean_id_record
              html_redirect_to \
                params.permit!.merge(id: clean_id),
                status: :moved_permanently
            end
          else
            if record.respond_to?(:slug) && id != record.slug
              html_redirect_to \
                params.permit!.merge(id: record.slug),
                status: :moved_permanently
            end
          end
        end
      end
    end

    def find_local_record(scope, param = params[:id])
      if params[:draft]
        if draft = scope.detect { _1.slug == param }
          return draft
        else
          raise ActiveRecord::RecordNotFound
        end
      end

      local_record =
        if published_on = param[/\A(\d{4}-\d{2}-\d{2})/, 1]&.then { Date.parse(_1) }
          scope.find_by(published_on:)
        else
          scope.find_by(slug: param)
        end

      unless local_record
        raise ActiveRecord::RecordNotFound
      end

      unless param == local_record.to_param
        html_redirect_to \
          [:web, local_record],
          status: :moved_permanently
      end

      local_record
    end

    def current_language = Language.new(locale: I18n.locale)

    def validate_turnstile
      return true unless Rails.env.production?
      return false if params["cf-turnstile-response"].blank?

      success = params["cf-turnstile-success"]

      [true, false].each do |value|
        return value if success == value.to_s
      end

      ReportError.call %(Cloudflare Turnstile Success param neither "true" nor "false", got: #{success.inspect})

      false
    end

    def allowed_host?(url)
      url
        .unless(-> { _1.present? }) { return false }
        .unless(URLFormatValidator.regex) { "https://#{_1}" }
        .then { Addressable::URI.parse(_1).host }
        .then {
          _1.match?(/\b#{Rails.application.env_credentials.host!}\z/) ||
            _1.in?(::URLManager.domains)
        }
    end

    def append_info_to_payload(payload)
      super

      payload.merge! \
        request_id: request.uuid,
        remote_ip:  request.remote_ip

      if ::Current.user
        payload.merge! \
          current_user_id:   ::Current.user.id,
          current_user_name: ::Current.user.name
      end
    end

    private

      def add_site_name_to_page_title? = true

      def expires_soon
        expires_in 1.hour,
          public:     true,
          "s-maxage": 1.day
      end

      def set_noindex_header
        headers["X-Robots-Tag"] = "noindex"
      end

      def page_meta_title(_scope: nil, **)
        *i18n_scope, i18n_key = [*action_i18n_scope, :meta_title, _scope].compact
        t i18n_key,
          scope:   i18n_scope,
          default: Loofah.fragment(page_title).text(encode_special_chars: false).html_safe,
          **
      end

      def page_meta_description(_scope: nil, **)
        *i18n_scope, i18n_key = [*action_i18n_scope, :meta_description, _scope].compact
        t i18n_key,
          scope:   i18n_scope,
          default: page_meta_title,
          **
      end

      def turbo_response_stream(
        redirect:             nil,
        success_message:      nil,
        error_message:        nil,
        reload_main:          false,
        reload_main_or_modal: false,
        reload_frames:        [],
        close_modal:          false)

        if success_message && error_message
          raise "success_message and error_message cannot both be given."
        end

        if reload_main_or_modal && close_modal
          raise "reload_main_or_modal and close_modal cannot both be given."
        end

        %i[success_message error_message].each do |var|
          if value = binding.local_variable_get(var)
            binding.local_variable_set \
              var,
              resolve_message(value)
          end
        end

        turbo_stream.append_all(:body) do
          view_context.tag.div \
            data: stimco(:turbo_response,
              redirect:      redirect&.then { url_for _1 },
              reload_frames: Array(reload_frames),
              close_modal:,
              reload_main:,
              reload_main_or_modal:,
              success_message:,
              error_message:
            )
        end
      end

      def render_turbo_response(**kwargs)
        streams = [
          turbo_response_stream(**kwargs),
          *(Array(yield) if block_given?)
        ]

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: streams
          end
        end
      end

      def html_redirect_to(options = {}, response_options = {})
        response_options[:status] ||= :see_other

        respond_to do |format|
          format.html do
            redirect_to options, response_options
          end
        end
      end

      def html_redirect_back_or_to(url, options = {})
        respond_to do |format|
          format.html do
            redirect_back_or_to url,
              status: :see_other,
              **options
          end
        end
      end

      def non_dev_fresh_when(...)
        !Rails.env.development? && fresh_when(...)
      end

      def route_exists?(path)
        suppress NoMethodError do
          !!url_for(path)
        end
      end
  end
end
