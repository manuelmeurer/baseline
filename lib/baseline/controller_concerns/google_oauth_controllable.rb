# frozen_string_literal: true

module Baseline
  module GoogleOauthControllable
    def self.[](email_domain)
      Module.new do
        extend ActiveSupport::Concern

        included do
          allow_unauthenticated_access
        end

        def authorize
          google_url = oauth_client
            .auth_code
            .authorize_url(
              redirect_uri:,
              scope:       "openid email profile",
              access_type: "offline"
            )
          redirect_to google_url,
            allow_other_host: true
        end

        def callback
          if error = params[:error]
            add_flash :alert, "An error occurred: #{error}. Please try again."
            redirect_to %i[admin login]
            return
          end

          token = oauth_client
            .auth_code
            .get_token(
              params[:code],
              redirect_uri:
            )

          email, first_name, last_name = token
            .get("https://openidconnect.googleapis.com/v1/userinfo")
            .then { JSON.parse(_1.body) }
            .fetch_values("email", "given_name", "family_name")

          unless email.ends_with?("@#{email_domain}")
            add_flash :alert, "Please log in with your #{email_domain} account."
            redirect_to %i[admin login]
            return
          end

          admin_user = AdminUser
            .create_with(first_name:, last_name:)
            .find_or_create_by!(email:)

          authenticate(admin_user)

          add_flash :notice, "Successfully logged in."
          redirect_to %i[admin root]
        end

        private

          def redirect_uri = admin_oauth_callback_url(return_to: params[:return_to])

          def oauth_client
            Rails
              .application
              .env_credentials
              .admin_google_auth!
              .then {
                OAuth2::Client.new \
                  _1.client_id!,
                  _1.client_secret!,
                  site:          "https://oauth2.googleapis.com",
                  token_url:     "/token",
                  authorize_url: "https://accounts.google.com/o/oauth2/v2/auth"
              }
          end
      end
    end

    def self.included(base)
      base.include self[Rails.application.env_credentials.host!]
    end
  end
end
