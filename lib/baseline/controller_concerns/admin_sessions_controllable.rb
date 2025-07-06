# frozen_string_literal: true

module Baseline
  module AdminSessionsControllable
    def self.[](email_domain)
      Module.new do
        extend ActiveSupport::Concern

        included do
          enforce_unauthenticated_access except: :destroy
        end

        define_method :new do
          @email_domain = email_domain
          render "baseline/admin_sessions/new"
        end

        def create
          if Rails.env.development?
            admin_user = AdminUser.find(params[:admin_user_id])
            authenticate_and_redirect(admin_user)
          else
            # cookies[:return_to] = {
            #   value:   params[:return_to],
            #   expires: 1.hour.from_now
            # }
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
        end

        def destroy
          unauthenticate
          redirect_to %i[admin login],
            notice: "Successfully logged out."
        end

        define_method :oauth_callback do
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

          authenticate_and_redirect(admin_user)
        end

        private

          def redirect_uri = admin_oauth_callback_url

          def authenticate_and_redirect(admin_user)
            authenticate(admin_user)
            add_flash :notice, "Successfully logged in."
            redirect_to after_authentication_url
          end

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
