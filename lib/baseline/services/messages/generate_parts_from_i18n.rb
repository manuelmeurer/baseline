# frozen_string_literal: true

module Baseline
  module Messages
    class GeneratePartsFromI18n < ApplicationService
      def call(message_or_group, recipient = nil, admin_user: ::Current.admin_user)
        case
        when message_or_group.is_a?(MessageGroup)
          @message_group = message_or_group
          @message_class = @message_group.message_class
          @kind          = @message_group.kind.to_sym
          @messageable   = @message_group.messageable
          @recipient     = recipient
          locale         = @message_group.locale
        when recipient
          raise Error, "Cannot pass a message and a recipient. Assign the recipient to the message instead."
        else
          @message       = message_or_group
          @message_class = @message.class
          @kind          = @message.kind.to_sym
          @messageable   = @message.messageable
          @recipient     = @message.recipient
          locale         = @message.recipient&.locale || I18n.locale
        end

        @admin_user             = admin_user
        @message_class_i18n_key = @message_class.to_s.underscore.to_sym

        I18n.with_locale locale do
          do_generate
        end
      end

      private

        def do_generate
          if persisted_message_group
            sections = persisted_message_group
              .sections
              .map(&:do_clone)
              .if(i18n_params.present?) do |new_sections|
                new_sections.each do |section|
                  if section.headline.present?
                    section.headline = I18n.interpolate(section.headline, i18n_params)
                  end
                  if section.content.present?
                    section.content = I18n.interpolate(section.content.body.to_html, i18n_params)
                  end
                end
                new_sections
              end
          else
            sections = body_from_i18n(:email).then {
              Baseline::Sections::InitializeFromMarkdown.call _1
            }
          end

          parts = {
            sections:
          }

          parts[:subject] =
            persisted_message_group ?
              persisted_message_group.subject&.then { I18n.interpolate _1, i18n_params } :
              subject_from_i18n

          if defined?(SlackDelivery)
            parts[:slack_body] =
              persisted_message_group ?
                persisted_message_group.slack_body&.then { I18n.interpolate _1, i18n_params } :
                body_from_i18n(:slack)
          end

          update_parts_service_name =
            ("Messages::Update#{@message.class}#{@message.kind.classify}Parts" if defined?(@message)) ||
            ("MessageGroups::Update#{@message_group.kind.classify}Parts" unless @message_group.persisted?)

          if update_parts_service = update_parts_service_name&.safe_constantize
            parts = update_parts_service.call(parts, @message || @message_group)
          end

          parts
        end

        def persisted_message_group
          if defined?(@message_group) && @message_group.persisted?
            @message_group
          end
        end

        def i18n_params
          @i18n_params ||= [
            common_i18n_params,
            messageable_i18n_params,
            recipient_class_i18n_params,
            recipient_i18n_params,
            kind_i18n_params
          ].compact_blank
            .inject(:merge)
        end

        def common_i18n_params
          messageable_admin_cms_url = if @messageable.is_a?(ActiveRecord::Base) && defined?(::Avo)
            suppress NoMethodError do
              ::Avo::Engine.routes.url_helpers.url_for([:resources, @messageable])
            end
          end

          {
            messageable_admin_cms_url:,
            admin_user_first_name: @admin_user&.first_name,
            admin_user_name:       @admin_user&.name,
            today:                 l(Date.current)
          }
        end

        def messageable_i18n_params     = {}
        def recipient_class_i18n_params = {}
        def kind_i18n_params            = {}

        def recipient_i18n_params
          resolve_with_recipient(
            recipient_first_name: -> { _1.try(:nickname_or_first_name) || _1.first_name },
            recipient_last_name:  -> { _1.last_name },
            recipient_name:       -> { _1.name      },
            recipient_gender:     -> { _1.try(:gender)&.then { |gender| t gender, scope: :genders } }
          )
        end

        def optional_i18n_scopes = []

        def body_from_i18n(*i18n_key_suffix)
          fetch_from_i18n \
            :messages,
            @message_class_i18n_key,
            @kind,
            *i18n_key_suffix
        end

        def subject_from_i18n
          fetch_from_i18n \
            :messages,
            :subjects,
            @message_class_i18n_key,
            @kind
        end

        def fetch_from_i18n(*i18n_key)
          translate_with_optional_scopes \
            i18n_key,
            optional_i18n_scopes.compact.map(&:to_sym),
            **i18n_params
        end

        def resolve_with_recipient(hash)
          hash.map {
            [_1, @recipient ? _2.call(@recipient) : "%{#{_1}}"]
          }.to_h
        end
    end
  end
end
