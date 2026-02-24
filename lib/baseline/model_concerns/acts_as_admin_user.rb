# frozen_string_literal: true

module Baseline
  module ActsAsAdminUser
    extend ActiveSupport::Concern

    included do
      if schema_columns.key?(:tokens)
        store_accessor :tokens,
          :todoist_access_token,
          :google_access_token,
          :google_refresh_token
      end
    end

    class_methods do
      delegate :email_signature, to: :new
    end

    def email_signature = _do_generate_email_signature
  end
end
