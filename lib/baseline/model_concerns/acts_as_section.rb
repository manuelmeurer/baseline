# frozen_string_literal: true

module Baseline
  module ActsAsSection
    extend ActiveSupport::Concern

    included do
      include HasFriendlyID,
              HasPosition[:sectionable],
              TouchAsync[:sectionable]

      has_rich_text :content

      belongs_to :sectionable,
        polymorphic: true,
        inverse_of:  :sections

      private

        def should_generate_new_friendly_id?
          headline_changed? ||
            super
        end

        def custom_slug
          [
            new_slug_identifier,
            headline
          ].join(" ")
        end
    end

    class_methods do
      def clone_fields = %i[headline content]
    end

    def content_html
      Nokogiri::HTML.fragment(content.to_s)
    end

    def to_s = headline
  end
end
