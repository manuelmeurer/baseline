# frozen_string_literal: true

module Baseline
  class Language
    include ActiveModel::Model

    LEVELS = %i[
      basic
      intermediate
      fluent
      primary
    ].freeze
    ATTRIBUTES = %i[
      locale
      level
    ].freeze

    attr_reader *ATTRIBUTES

    ATTRIBUTES.each do |attribute|
      define_method "#{attribute}=" do |value|
        instance_variable_set :"@#{attribute}", value&.to_s
      end
    end

    validates :locale,
      presence: true,
      inclusion: {
        in:          proc { locales.map(&:to_s) },
        allow_blank: true
      }

    validates :level,
      inclusion: {
        in:        proc { levels.map(&:to_s) },
        allow_nil: true
      }

    class << self
      def all      = locales.map { new locale: _1 }
      def defaults = %i[de en].map { new locale: _1 }
      def locales  = I18n.t(:names, scope: :languages).keys
      def levels   = LEVELS
    end

    locales.each do |locale|
      locale_method = locale.to_s.tr("-", "_")

      define_method "#{locale_method}?" do
        self.locale&.to_sym == locale.to_sym
      end

      define_singleton_method locale_method do |level = nil|
        new locale:, level: level.to_s.presence
      end
    end

    levels.each do |level|
      define_method "#{level}?" do
        self.level&.to_sym == level
      end
    end

    def name
      if locale
        I18n.t locale, scope: %i[languages names]
      end
    end

    def to_s
      [
        name,
        level&.then { "(#{I18n.t _1, scope: %i[languages levels]})" }
      ].compact
        .join(" ")
    end

    def ==(other)
      other.is_a?(Language) &&
        ATTRIBUTES.all? {
          public_send(_1).presence == other.public_send(_1).presence
        }
    end
    alias eql? ==

    def hash
      ATTRIBUTES
        .map { public_send(_1) }
        .hash
    end
  end
end
