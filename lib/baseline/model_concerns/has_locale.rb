# frozen_string_literal: true

module Baseline
  module HasLocale
    def self.[](attribute = :locale, default: nil, valid_locales: I18n.available_locales, validate_presence: true)
      language_attribute = attribute.sub(/locale\z/, "language")

      if attribute == language_attribute
        raise %(Attribute must equal or end with "locale".)
      end

      Module.new do
        extend ActiveSupport::Concern

        included do
          if default
            attribute attribute, default:
          end

          if validate_presence
            validates attribute, presence: true
            validates language_attribute, presence: true
          end

          validates attribute, inclusion: { in: valid_locales.map(&:to_s), allow_blank: true }

          validate do
            language = public_send(language_attribute)
            if language&.invalid?
              errors.add attribute, message: "is invalid: #{language.errors.full_messages.to_sentence}"
            end
          end
        end

        define_method "#{attribute}_without_region" do
          public_send(attribute)&.sub(/-[A-Z]{2}\z/, "")
        end

        define_method language_attribute do
          public_send(attribute)
            &.then {
              Language.new locale: _1
            }
        end

        define_method "#{language_attribute}=" do |value|
          if value.is_a?(Language)
            value = value.locale
          end
          public_send "#{attribute}=", value
        end
      end
    end

    def self.included(base)
      base.include self[]
    end
  end
end
