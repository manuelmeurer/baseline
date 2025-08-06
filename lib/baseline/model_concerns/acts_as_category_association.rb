# frozen_string_literal: true

module Baseline
  module ActsAsCategoryAssociation
    extend ActiveSupport::Concern

    included do
      belongs_to :category
      belongs_to :categorizable, polymorphic: true

      validates :category, uniqueness: { scope: %i[categorizable_id categorizable_type] }
    end
  end
end
