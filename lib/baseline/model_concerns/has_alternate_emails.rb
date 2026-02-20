# frozen_string_literal: true

module Baseline
  module HasAlternateEmails
    extend ActiveSupport::Concern

    included do
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
  end
end
