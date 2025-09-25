# frozen_string_literal: true

module Baseline
  module ActsAsAdminUser
    extend ActiveSupport::Concern

    class_methods do
      delegate :email_signature, to: :new
    end

    def email_signature = _do_generate_email_signature
  end
end
