# frozen_string_literal: true

module Baseline
  module AdminUsers
    class SetEmailSignatures < ApplicationService
      def call(admin_user)
        unless admin_user.uplink_email?
          raise Error, "Can only set email signature for admin with Uplink email."
        end

        gmail   = Baseline::External::Google::Oauth::Service.new(:gmail)
        send_as = Google::Apis::GmailV1::SendAs.new(signature: admin_user.email_signature)

        # TODO: The user needs AUTH_GMAIL_SETTINGS_BASIC scope for this to work.
        # An alternative to giving each user Oauth permissions is domain wide delegation:
        # https://support.google.com/a/answer/162106?hl=en#start&setup&view&zippy=%2Cbefore-you-begin%2Cset-up-domain-wide-delegation-for-a-client%2Cview-edit-or-delete-clients-and-scopes
        # https://admin.google.com/u/2/ac/owl/domainwidedelegation
        # https://console.cloud.google.com/apis/credentials?authuser=2&hl=de&project=uplink-2&supportedpurview=project
        # https://developers.google.com/identity/protocols/oauth2/scopes
        gmail.update_user_setting_send_as("me", admin_user.email, send_as)
      end
    end
  end
end
