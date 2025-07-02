# frozen_string_literal: true

module Baseline
  module HasEmail
    def self.[](attribute)
      Module.new do
        extend ActiveSupport::Concern

        included do
          normalizes attribute,
            with: -> { _1.strip.downcase }

          validates attribute,
            email: {
              allow_nil: true
            }
        end
      end
    end

    def self.included(base)
      base.include self[:email]
    end
  end
end
