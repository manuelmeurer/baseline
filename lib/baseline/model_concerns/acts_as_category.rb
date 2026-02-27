# frozen_string_literal: true

module Baseline
  module ActsAsCategory
    extend ActiveSupport::Concern

    included do
      include HasFriendlyID

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

      def valid_for(resource_or_class)        = all
      def valid_groups_for(resource_or_class) = groups.keys
    end

    def to_s(include_group: true)
      [
        (group&.humanize if include_group),
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
