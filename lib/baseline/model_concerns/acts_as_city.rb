# frozen_string_literal: true

module Baseline
  module ActsAsCity
    extend ActiveSupport::Concern

    included do
      include HasFriendlyID[:name],
              HasStateAndCountry

      geocoded_by :name_state_and_country

      has_many :locations

      validates :name, presence: true, uniqueness: { case_sensitive: false, scope: %i[country state] }
      validates :latitude, presence: true
      validates :longitude, presence: true

      scope :candidate_resources, ->(filter) {
        if filter
          where_ilike(:name, filter)
        end
      }
    end

    class_methods do
      def method_missing(method, ...)
        find_by(slug: method.to_s) || super
      end

      def main
        slugs = %w[
          berlin
          hamburg
          muenchen
        ]

        City
          .where(slug: slugs)
          .in_order_of(:slug, slugs)
      end
    end

    def method_missing(method, ...)
      slug, suffix = method.to_s[0..-2], method.to_s.last

      if suffix == "?"
        if self.slug == slug
          return true
        else
          begin
            self.class.friendly.find(slug)
          rescue ActiveRecord::RecordNotFound
          else
            return false
          end
        end
      end

      super
    end

    def name_state_and_country
      [name, state, country.to_s].compact_blank.join(" ")
    end
  end
end
