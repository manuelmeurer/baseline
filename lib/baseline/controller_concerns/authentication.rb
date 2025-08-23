# frozen_string_literal: true

module Baseline
  module Authentication
    def self.[](user_class_name)
      Module.new do
        extend ActiveSupport::Concern

        included do
          class_eval { @auth_user_class_name = user_class_name }

          before_action do
            if params[:t].present? && user = auth_user_class.try(:find_by_login_token, params[:t])
              authenticate user
              redirect_to params.permit!.except(:t)
            end
          end

          before_action :require_authentication

          helper_method def authenticated?   = !!resume_session
          helper_method def unauthenticated? = !authenticated?
        end

        class_methods do
          def auth_user_class_name
            @auth_user_class_name || superclass.auth_user_class_name
          end

          def allow_unauthenticated_access(**)
            # If the `require_authentication` callback has not been defined, an ArgumentError is raised.
            skip_before_action(:require_authentication, **)
          rescue ArgumentError
          else
            before_action(:resume_session, **) # Set Current.user
          end

          def require_unauthenticated_access(**)
            allow_unauthenticated_access(**)

            before_action(**) do
              if current_user
                html_redirect_back_or_to \
                  [::Current.namespace, :root],
                  alert: "You are already logged in."
              end
            end
          end
        end

        private

          def auth_user_class               = @auth_user_class ||= self.class.auth_user_class_name.constantize
          def auth_user_class_identifier    = self.class.auth_user_class_name.underscore
          def cookie_name                   = :"#{auth_user_class_identifier}_id"
          def current_user                  = ::Current.public_send(auth_user_class_identifier)
          def set_current_user(value = nil) = ::Current.public_send("#{auth_user_class_identifier}=", value)

          def require_authentication
            request_authentication unless authenticated?
          end

          def resume_session
            set_current_user(
              current_user ||
                cookies
                  .signed[cookie_name]
                  &.then {
                    auth_user_class.find_by(id: _1)
                  }
            )
          end

          def request_authentication
            session[:return_to] = request.url
            redirect_to [::Current.namespace, :login],
              alert: "Please log in to continue."
          end

          def after_authentication_url
            session.delete(:return_to) ||
              [::Current.namespace, :root]
          end

          def authenticate_and_redirect(user)
            authenticate(user)
            html_redirect_to after_authentication_url,
              notice: "Successfully logged in."
          end

          def authenticate(user)
            unless user.is_a?(auth_user_class)
              raise "Unexpected user class: #{user.class}"
            end

            set_current_user(user)
            cookies.signed.permanent[cookie_name] = {
              value:     user.id,
              httponly:  true,
              same_site: :lax
            }
          end

          def unauthenticate
            set_current_user
            cookies.delete(cookie_name)
          end
      end
    end

    def self.included(base)
      base.include self["User"]
    end
  end
end
