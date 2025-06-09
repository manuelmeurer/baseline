# frozen_string_literal: true

module Baseline
  module Messages
    class GeneratePartsFromI18n < ApplicationService
      def call(message_or_group, recipient = nil, admin_user: ::Current.admin_user)
        case
        when message_or_group.is_a?(MessageGroup)
          @message_group = message_or_group
          @message_class, @kind, @messageable, @recipient = [
            @message_group.message_class,
            @message_group.kind.to_sym,
            @message_group.messageable,
            recipient
          ]
        when recipient
          raise Error, "Cannot pass a message and a recipient. Assign the recipient to the message instead."
        else
          @message = message_or_group
          @message_class, @kind, @messageable, @recipient = [
            @message.class,
            @message.kind.to_sym,
            @message.messageable,
            @message.recipient
          ]
        end

        @admin_user             = admin_user
        @message_class_i18n_key = @message_class.to_s.underscore

        do_generate
      end

      private

        def do_generate
          subject, body =
            if persisted_message_group
              %i[subject body].map {
                I18n.interpolate \
                  persisted_message_group.public_send(_1),
                  i18n_params
              }
            else
              [
                subject_from_i18n,
                body_from_i18n
              ]
            end

          {
            subject:,
            body:
          }
        end

        def persisted_message_group
          if @message_group&.persisted?
            @message_group
          end
        end

        def i18n_params
          @i18n_params ||= {}
          @i18n_params[I18n.locale] ||= [
            common_i18n_params,
            messageable_i18n_params,
            recipient_class_i18n_params,
            recipient_i18n_params,
            custom_i18n_params
          ].compact_blank
            .inject(:merge)
        end

        def common_i18n_params
          {
            admin_user_first_name: @admin_user&.first_name,
            admin_user_name:       @admin_user&.name,
            today:                 l(Date.current)
          }
        end

        def messageable_i18n_params     = {}
        def recipient_class_i18n_params = {}
        def custom_i18n_params          = {}

        def recipient_i18n_params
          resolve_with_recipient(
            recipient_first_name: -> { _1.try(:nickname_or_first_name) || _1.first_name },
            recipient_last_name:  -> { _1.last_name },
            recipient_name:       -> { _1.name      },
            recipient_gender:     -> { _1.try(:gender)&.then { |gender| t gender, scope: :genders } }
          )
        end

        def optional_i18n_scopes = []

        def body_from_i18n(*i18n_keys)
          _optional_i18n_scopes = optional_i18n_scopes.compact

          _optional_i18n_scopes
            .size
            .downto(0)
            .map { _optional_i18n_scopes.take(_1) }
            .map {
              [
                :messages,
                @message_class_i18n_key,
                @kind,
                *i18n_keys,
                *_1
              ].compact
                .join(".")
            }.lazy
            .map {
              t(_1, **i18n_params, default: nil)&.chomp
            }.detect(&:present?)
        end

        def subject_from_i18n
          i18n_scope = [
            :messages,
            :subjects,
            @message_class_i18n_key,
            @kind
          ].compact

          t i18n_scope.last,
            scope:   i18n_scope[0..-2],
            default: nil,
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
