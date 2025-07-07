# frozen_string_literal: true

module Baseline
  module GoogleOauthControllable
    extend ActiveSupport::Concern

    included do
      allow_unauthenticated_access
    end

    def authorize
      url =
        if ::Current.admin_user
          # Authorization
          External::Google::Oauth::Authorizer
            .new(::Current.admin_user)
            .auth_url(::Current.admin_user.email)
        else
          # Authentication
          oauth_client
            .auth_code
            .authorize_url(
              redirect_uri:,
              scope:       "openid email profile",
              access_type: "offline"
            )
        end

      redirect_to url,
        allow_other_host: true
    end

    def callback
      if error = params[:error]
        add_flash :alert, "An error occurred: #{error}. Please try again."
        url = ::Current.admin_user ?
          %i[admin root] :
          %i[admin login]
        redirect_to url
        return
      end

      ::Current.admin_user ?
        authorization_callback :
        authentication_callback
    end

    private

      def redirect_uri = admin_oauth_callback_url

      def oauth_client
        require "oauth2"

        Rails
          .application
          .env_credentials
          .google!
          .oauth!
          .then {
            OAuth2::Client.new \
              _1.client_id!,
              _1.client_secret!,
              site:          "https://oauth2.googleapis.com",
              token_url:     "/token",
              authorize_url: "https://accounts.google.com/o/oauth2/v2/auth"
          }
      end

      def authorization_callback
        code, scope = params.values_at(:code, :scope)
        if code.blank? || scope.blank?
          render plain: "Code and/or scope missing."
          return
        end

        authorizer = External::Google::Oauth::Authorizer.new(::Current.admin_user)

        unless scope.split == authorizer.scopes
          render plain: "Scopes don't match."
          return
        end

        credentials = authorizer.auth_credentials(code)
        %i[access_token refresh_token].each {
          ::Current.admin_user.public_send \
            "google_#{token}=",
            credentials.public_send(_1)
        }
        ::Current.admin_user.save!

        if respond_to?(:after_authorization, true)
          after_authorization
        end

        add_flash :notice, "Successfully authorized."
        redirect_to %i[admin root]
      end

      def authentication_callback
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

        find_and_authenticate_admin_user \
          email, first_name, last_name
      end

      def find_and_authenticate_admin_user(email, first_name, last_name)
        admin_user = AdminUser
          .create_with(first_name:, last_name:)
          .find_or_create_by!(email:)

        authenticate_and_redirect(admin_user)
      end
  end
end
