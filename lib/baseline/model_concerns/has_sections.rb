# frozen_string_literal: true

module Baseline
  module HasSections
    extend ActiveSupport::Concern

    included do
      include HasAssociationWithPosition[:sections]

      has_many :sections,
        -> { order(:position) },
        dependent:  :destroy,
        as:         :sectionable,
        inverse_of: :sectionable

      accepts_nested_attributes_for :sections,
        allow_destroy: true,
        reject_if:     -> { _1.values_at(:headline, :content).all?(&:blank?) }

      after_commit do
        sections.select do |section|
          section.headline.blank? &&
            section.content.blank?
        end.each(&:destroy)
      end
    end

    def sections_md
      sections
        .map(&:_do_render_as_markdown)
        .join("\n\n")
    end

    def sections_md=(value)
      # TODO: remove this when Avo does not assign `{}` anymore.
      # See emails with Avo team from August 2025.
      return unless value.nil? || value.is_a?(String)

      self.sections =
        value.present? ?
        Baseline::Sections::InitializeFromMarkdown.call(value) :
        []
    end
  end
end
