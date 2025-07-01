# frozen_string_literal: true

module Baseline
  module HasFriendlyID
    def self.[](method = :custom_slug, use: :history)
      Module.new do
        extend ActiveSupport::Concern

        included do
          extend FriendlyId

          friendly_id(method, use:)

          after_create do
            if slug_identifier
              with slug: slug_identifier do
                create_slug
              end
            end
          end
        end

        define_method :to_key do
          [use ? slug : public_send(method)]
        end

        if method == :custom_slug
          private def custom_slug = new_slug_identifier
        end

        def slug_identifier
          if slug.present?
            slug[/\A([a-f0-9]{6})-/, 1]
          end
        end

        def new_slug_identifier
          # If the current slug already has an identifier, return that.
          if slug_identifier
            return slug_identifier
          end

          retries = 100
          Octopoller.poll wait: false, retries: do
            new_slug_identifier = SecureRandom.hex(3)
            begin
              self.class.friendly.find(new_slug_identifier)
            rescue ActiveRecord::RecordNotFound
              return new_slug_identifier
            else
              :re_poll
            end
          end
        rescue Octopoller::TooManyAttemptsError
          raise "Could not find a unique slug identifier for #{inspect} after #{retries} attempts."
        end
      end
    end

    def self.included(base)
      base.include self[]
    end
  end
end
