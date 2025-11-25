# frozen_string_literal: true

module Baseline
  module HasLocale
    def self.[](attribute = :locale, valid_locales: I18n.available_locales, validate_presence: true)
      language_attribute = attribute.sub(/locale\z/, "language")

      if attribute == language_attribute
        raise %(Attribute must equal or end with "locale".)
      end

      Module.new do
        extend ActiveSupport::Concern

        included do
          if validate_presence
            [attribute, language_attribute].each {
              validates _1, presence: validate_presence
            }
          end

          validates attribute, inclusion: { in: valid_locales.map(&:to_s), allow_nil: true }

          validate do
            next if errors[attribute].any?

            language = public_send(language_attribute)
            if language&.invalid?
              errors.add attribute, message: "is invalid: #{language.errors.full_messages.to_sentence}"
            end
          end
        end

        class_methods do
          define_method "valid_#{attribute.pluralize}" do
            valid_locales
          end
        end

        define_method "#{attribute}_without_region" do
          public_send(attribute)&.then {
            _1.split("-").first
          }
        end

        define_method language_attribute do
          public_send(attribute)&.then {
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
