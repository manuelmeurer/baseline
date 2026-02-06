# frozen_string_literal: true

module Baseline
  module ApplicationAvoShared
    def resolve_message(arg)
      case
      when arg.is_a?(String)
        arg
      when arg.is_a?(Array) && arg.one? && arg.first.is_a?(String)
        arg.first
      else
        t [
          *action_i18n_scope(action_name),
          *arg
        ].join(".")
      end
    end

    def add_flash(type, *message_or_i18n_keys, now: false)
      message = resolve_message(message_or_i18n_keys)

      valid_types = %i[alert info notice warning]
      unless type.in?(valid_types)
        raise "type is not valid, must be one of: #{valid_types.join(", ")}"
      end

      desired_flash =
        now ?
        flash.now :
        flash

      desired_flash[type] = [
        desired_flash[type],
        message
      ].compact_blank.join("\n\n")
    end
  end
end
