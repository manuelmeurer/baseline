# frozen_string_literal: true

module Baseline
  module AdminSessionsControllable
    extend ActiveSupport::Concern

    included do
      require_unauthenticated_access except: :destroy
    end

    def new
      render "baseline/admin_sessions/new"
    end

    def create
      if Rails.env.development?
        unless admin_user_id = params[:admin_user_id]
          raise "Admin user ID is missing."
        end
        AdminUser
          .find(admin_user_id)
          .then {
            authenticate_and_redirect(_1)
          }
        return
      end

      redirect_to %i[admin oauth authorize]
    end

    def destroy
      unauthenticate
      add_flash :notice, "Successfully logged out."
      redirect_to %i[admin login]
    end
  end
end
