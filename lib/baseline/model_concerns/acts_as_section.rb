# frozen_string_literal: true

module Baseline
  module ActsAsSection
    extend ActiveSupport::Concern

    included do
      include HasFriendlyID,
              HasPosition[:sectionable],
              TouchAsync[:sectionable]

      has_rich_text :content_de
      has_rich_text :content_en

      translates_with_fallback :headline, :content

      belongs_to :sectionable,
        polymorphic: true,
        inverse_of:  :sections
    end

    class_methods do
      def clone_fields = locale_columns(:headline, :content)
      def locales      = %i[de en]
    end

    def content_html(locale: nil)
      content(locale:)
        .to_s
        .then {
          Nokogiri::HTML.fragment _1
        }
    end

    def to_s = headline

    private

      def should_generate_new_friendly_id?
        headline_de_changed? ||
          headline_en_changed? ||
          super
      end

      def custom_slug
        [
          new_slug_identifier,
          I18n.with_locale(:en) { headline }
        ].join(" ")
      end
  end
end
