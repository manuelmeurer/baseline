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
        reject_if:     -> { _1.values_at(*Section.locale_columns(:headline, :content)).all?(&:blank?) }

      after_commit do
        sections.select do |section|
          Section.locale_columns(:headline, :content).all? {
            section.public_send(_1).blank?
          }
        end.each(&:destroy)
      end
    end
  end
end
