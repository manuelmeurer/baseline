# frozen_string_literal: true

module Baseline
  module HasPassword
    def self.[](default:)
      Module.new do
        extend ActiveSupport::Concern

        included do
          has_secure_password

          validates :password,
            length: {
              minimum:   8,
              maximum:   50,
              allow_nil: true
            }

          if default
            before_validation on: :create do
              self.password ||= default
            end
          end
        end

        if default
          def password_changed?
            !authenticate(default)
          end
        end
      end
    end

    def self.included(base)
      base.include self[default: nil]
    end
  end
end
