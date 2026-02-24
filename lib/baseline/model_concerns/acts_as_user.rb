# frozen_string_literal: true

module Baseline
  module ActsAsUser
    extend ActiveSupport::Concern

    included do
      include Deactivatable,
              HasDummyImageAttachment[:photo],
              HasEmail,
              HasEmailConfirmations,
              HasFirstAndLastName,
              HasGender,
              HasLocale,
              HasLoginToken,
              HasPassword

      after_initialize if: :new_record? do
        if remember_token.blank?
          reset_remember_token!
        end
      end

      has_one_attached_and_accepts_nested_attributes_for :photo

      validates :photo, content_type: common_image_file_types

      validate do
        invalid_alternate_emails = alternate_emails.select { EmailValidator.invalid? _1 }
        case
        when invalid_alternate_emails.any?
          errors.add :alternate_emails, message: "contain invalid elements: #{invalid_alternate_emails.join(", ")}"
        when email.present? && alternate_emails.include?(email)
          errors.add :alternate_emails, message: "must not contain email #{email}"
        end
      end
    end

    class_methods do
      def status_scopes
        {
          active:      nil,
          deactivated: nil
        }
      end

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

    def to_s
      [
        name || "Anonymous",
        email&.then { "(#{_1})" }
      ].compact.join(" ")
    end

    private def after_deactivate = reset_remember_token!
  end
end
