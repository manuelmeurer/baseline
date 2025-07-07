# frozen_string_literal: true

module Baseline
  module ControllerCore
    extend ActiveSupport::Concern

    included do
      include I18nScopes,
              RobotsSitemapManifest

      helper_method def specific_turbo_frame_request?(name_or_resource)
        name_or_resource
          .if(ActiveRecord::Base) { helpers.dom_id(_1) }
          .then { turbo_frame_request_id == _1.to_s }
      end

      helper_method def normalized_action_name(action = ::Current.action_name, reverse: false)
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
          .if(to_h) { _1.to_h }
      end

      helper_method def site_name
        t ::Current.namespace, scope: :site_names
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

        # Assign to ivar so data can be changed.
        @og_data ||= {}
        @og_data.reverse_merge(
          type:        "website",
          title:       [page_meta_title, site_name].join(" | "),
          description: page_meta_description,
          url:         url_for(only_path: false),
          site_name:,
          locale:
        )
      end

      helper_method def set_og_data(**data)
        @og_data ||= {}
        @og_data.merge! data
      end
    end

    class_methods do
      def redirect_to_clean_id_or_current_slug(only: :show, &block)
        before_action only: do
          id = params.fetch(:id)

          begin
            record = instance_exec(id, &block)
          rescue ActiveRecord::RecordNotFound => error
            cleaners = [
              -> { _1.delete_suffix(")") }
            ]
            clean_id = nil

            loop do
              raise error unless cleaner = cleaners.shift
              clean_id = cleaner.call(id)
              redo if clean_id == id
              record_found_with_clean_id = suppress ActiveRecord::RecordNotFound do
                instance_exec(clean_id, &block)
              end
              break if record_found_with_clean_id
            end

            html_redirect_to \
              params.permit!.merge(id: clean_id),
              status: :moved_permanently
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

    def current_language = Language.new(locale: I18n.locale)

    def render_turbo_response(
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

      stream = turbo_stream.append_all(:body) do
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

      streams = [
        stream,
        *(Array(yield) if block_given?)
      ]

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: streams
        end
      end
    end

    def validate_turnstile
      unless Rails.env.production?
        return true
      end

      if params["cf-turnstile-response"].blank?
        return false
      end

      success = params["cf-turnstile-success"]

      [true, false].each do |value|
        if success == value.to_s
          return value
        end
      end

      ReportError.call %(Cloudflare Turnstile Success param neither "true" nor "false", got: #{success.inspect})

      false
    end

    private

      def expires_soon
        expires_in 1.hour,
          public:     true,
          "s-maxage": 1.day
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

      def add_flash(type, text, now: false)
        valid_types = %i(alert info notice warning)
        unless type.in?(valid_types)
          raise "type is not valid, must be one of: #{valid_types.join(", ")}"
        end

        desired_flash = now ?
                        flash.now :
                        flash

        desired_flash[type] = [
          desired_flash[type],
          text
        ].compact_blank
         .join("\n\n")
      end

      def html_redirect_to(options = {}, response_options = {})
        response_options[:status] ||= :see_other

        respond_to do |format|
          format.html do
            redirect_to options, response_options
          end
        end
      end

      def html_redirect_back_or_to(url, params = {})
        respond_to do |format|
          format.html do
            redirect_back \
              fallback_location: url,
              status:            :see_other,
              **params
          end
        end
      end
  end
end
