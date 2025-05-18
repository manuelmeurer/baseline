# frozen_string_literal: true

module Baseline
  module ControllerCore
    extend ActiveSupport::Concern

    included do
      include I18nScopes,
              Robots

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
          .if(to_h) { _1.to_h }
      end

      helper_method def site_name
        t Current.namespace, scope: :site_names
      end

      helper_method def og_data
        locale = {
          de:      :de_DE,
          "de-DE": :de_DE,
          en:      :en_US,
          "en-US": :en_US,
          es:      :es_ES,
          fr:      :fr_FR,
          it:      :it_IT,
          nl:      :nl_NL,
          pl:      :pl_PL,
        }.fetch(I18n.locale)

        # Assign to ivar so data can be changed.
        @og_data ||= {
          type:        "website",
          site_name:   site_name,
          title:       [page_meta_title, site_name].join(" | "),
          description: page_meta_description,
          url:         url_for(only_path: false),
          locale:      locale
        }
      end

      helper_method def set_og_data(overwrite: true, **data)
        method = overwrite ? :merge! : :reverse_merge!
        og_data.public_send method, data
      end
    end

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
            redirect:             redirect&.then { url_for _1 },
            close_modal:          close_modal,
            reload_main:          reload_main,
            reload_main_or_modal: reload_main_or_modal,
            reload_frames:        Array(reload_frames),
            success_message:      success_message,
            error_message:        error_message
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

    private

      def page_meta_title(**)
        t :meta_title,
          scope:   action_i18n_scope,
          default: Loofah.fragment(page_title).text(encode_special_chars: false).html_safe,
          **
      end

      def page_meta_description(**)
        t :meta_description,
          scope:   action_i18n_scope,
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
