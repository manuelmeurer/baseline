# frozen_string_literal: true

module Baseline
  module SaveSlugIdentifier
    extend ActiveSupport::Concern

    included do
      after_create do
        with slug: slug_identifier do
          create_slug
        end
      end
    end
  end
end
