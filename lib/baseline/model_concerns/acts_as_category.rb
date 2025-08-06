# frozen_string_literal: true

module Baseline
  module ActsAsCategory
    extend ActiveSupport::Concern

    included do
      include Baseline::HasFriendlyID

      enum :group, groups,
        validate: true

      has_many :category_associations, dependent: :destroy

      scope :sorted, -> { order :group, :identifier }

      validates :identifier,
        presence:   true,
        uniqueness: { scope: :group }
    end

    class_methods do
      def add_categorizable(klass, many)
        has_many klass.to_s.underscore.pluralize.to_sym,
          through:     :category_associations,
          source:      :categorizable,
          inverse_of:  "category".if(many, &:pluralize).to_sym,
          source_type: klass.to_s
      end
    end

    def to_s
      [
        group&.humanize,
        identifier&.then { I18n.t _1, scope: [:categories, group] }
      ].compact
        .join(" » ")
    end

    private

      def custom_slug
        [group, identifier]
          .map { _1.tr("_", "-") }
          .join(" ")
      end
  end
end
