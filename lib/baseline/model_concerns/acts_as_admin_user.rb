# frozen_string_literal: true

module Baseline
  module ActsAsAdminUser
    def email_signature = AdminUsers::GenerateEmailSignature.call(self)
  end
end
