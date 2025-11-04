# frozen_string_literal: true

module Baseline
  module AdminSessionsControllable
    extend ActiveSupport::Concern

    OAUTH_AUTHORIZE_PATH = %i[admin oauth authorize]

    included do
      require_unauthenticated_access except: :destroy
    end

    def new
      @oauth_available = route_exists?(OAUTH_AUTHORIZE_PATH)
      render "baseline/admin_sessions/new"
    end

    def create
      case
      when Rails.env.development?
        unless admin_user_id = params[:admin_user_id]
          raise "Admin user ID is missing."
        end
        AdminUser
          .find(admin_user_id)
          .then {
            authenticate_and_redirect(_1.user)
          }
        return
      when credentials = params.permit(:email, :password).presence
        unless admin_user = User.authenticate_by(credentials)&.admin_user
          render_turbo_response \
            error_message: "No admin user with this email found."
          return
        end
        authenticate_and_redirect(admin_user.user)
      else
        redirect_to OAUTH_AUTHORIZE_PATH
      end
    end

    def destroy
      unauthenticate
      add_flash :notice, "Successfully logged out."
      redirect_to %i[admin login]
    end
  end
end
