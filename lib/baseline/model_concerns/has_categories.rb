# frozen_string_literal: true

module Baseline
  module HasCategories
    def self.[](many:)
      Module.new do
        extend ActiveSupport::Concern

        included do
          Category.add_categorizable(self, many)

          if many
            has_many :category_associations,
              as:         :categorizable,
              inverse_of: :categorizable,
              dependent:  :destroy

            has_many :categories, -> { sorted }, through: :category_associations

            accepts_nested_attributes_for :categories

            validate do
              invalid_categories = categories - Category.valid_for(self)
              if invalid_categories.any?
                errors.add :categories, message: "contain invalid elements: #{invalid_categories.join(', ')}"
              end
            end
          else
            has_one :category_association,
              as:         :categorizable,
              inverse_of: :categorizable,
              dependent:  :destroy

            has_one :category, through: :category_association

            accepts_nested_attributes_for :category

            validates :category, inclusion: { in: -> { Category.valid_for _1 } }
          end
        end

        unless many
          def category
            super || build_category
          end
        end
      end
    end

    def self.included(base)
      base.include self[many: true]
    end
  end
end
