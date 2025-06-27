# frozen_string_literal: true

module Baseline
  module HasFriendlyID
    def self.[](method = :custom_slug, use: :history)
      Module.new do
        extend ActiveSupport::Concern

        included do
          extend FriendlyId
          friendly_id method, use:
        end

        def to_key = [slug]

        private def custom_slug = slug_identifier
      end
    end

    def self.included(base)
      base.include self[]
    end
  end
end
