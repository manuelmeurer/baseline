# frozen_string_literal: true

module Baseline
  module ActsAsUser
    extend ActiveSupport::Concern

    included do
      include Deactivatable,
              HasDummyImageAttachment[:photo],
              HasEmail,
              HasFirstAndLastName,
              HasGender,
              HasLoginToken,
              HasPassword

      after_initialize do
        if new_record? && remember_token.blank?
          reset_remember_token!
        end
      end

      has_one_attached_and_accepts_nested_attributes_for :photo

      validates :photo, content_type: common_image_file_types
    end

    class_methods do
      def test_user
        find_by(email: Rails.application.env_credentials.mail_from!)
      end
    end

    def test_user?
      email == Rails.application.env_credentials.mail_from!
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
