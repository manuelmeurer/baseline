# frozen_string_literal: true

module Baseline
  module ActsAsUser
    extend ActiveSupport::Concern

    included do
      after_initialize do
        if new_record? && remember_token.blank?
          reset_remember_token!
        end
      end
    end

    def reset_remember_token!
      begin
        token = SecureRandom.hex(3)
      end while self.class.exists?(remember_token: token)
      self.remember_token = token
      save! if persisted?
    end
  end
end
