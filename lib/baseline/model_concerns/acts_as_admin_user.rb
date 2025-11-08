# frozen_string_literal: true

module Baseline
  module ActsAsAdminUser
    extend ActiveSupport::Concern

    included do
      if db_and_table_exist? && column_names.include?("tokens")
        store_accessor :tokens,
          :todoist_access_token,
          :google_access_token,
          :google_refresh_token
      end

      if db_and_table_exist? && column_names.include?("alternate_emails")
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

    class_methods do
      delegate :email_signature, to: :new
    end

    def email_signature = _do_generate_email_signature
  end
end
