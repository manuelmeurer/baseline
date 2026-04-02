# frozen_string_literal: true

module Baseline
  module AdminUsers
    class GenerateEmailSignature < ApplicationService
      def call(admin_user)
        base_signature = <<~SIGNATURE.chomp
          #{t :name, scope: :meta} - #{t :tagline, scope: :meta}
          #{home_url}

          #{ApplicationController.helpers.company_details}

          #{t :imprint, scope: :mailer}:
          #{imprint_url}
        SIGNATURE

        return base_signature unless admin_user.persisted?

        signature = [admin_user.name, ""]

        if admin_user.position.present?
          signature.push admin_user.position, ""
        end

        signature.push admin_user.email

        add_signature_parts(signature, admin_user)

        signature
          .push("", "---", "", base_signature)
          .join("\n")
      end

      private

        # Override these methods in your app to change the home and imprint URLs in the email signature.
        def home_url    = web_home_url
        def imprint_url = web_imprint_url

        # Override this method in your app to add custom signature parts based on the admin user.
        def add_signature_parts(signature, admin_user); end
    end
  end
end
