# frozen_string_literal: true

module Baseline
  module Authentication
    def self.[](scope = :all)
      Module.new do
        extend ActiveSupport::Concern

        included do
          class_eval { @auth_user_scope = "User.#{scope}" }

          before_action do
            if user = params[:t].presence&.then { auth_user_scope.try(:find_by_login_token, _1) }
              if respond_to?(:allow_login_with_token?, true)
                next unless allow_login_with_token?(user)
              end

              authenticate user

              redirect_to_return_to_or_to \
                params.permit!.except(:t)
            end
          end

          before_action :require_authentication

          helper_method def authenticated?   = !!resume_session
          helper_method def unauthenticated? = !authenticated?
        end

        class_methods do
          def auth_user_scope = @auth_user_scope || superclass.auth_user_scope

          def allow_unauthenticated_access(**)
            # If the `require_authentication` callback has not been defined, an ArgumentError is raised.
            skip_before_action(:require_authentication, **)
          rescue ArgumentError
          else
            before_action(:resume_session, **) # Set ::Current.user
          end

          def require_unauthenticated_access(**)
            allow_unauthenticated_access(**)

            before_action(**) do
              if ::Current.user
                html_redirect_back_or_to \
                  [::Current.namespace, :root],
                  alert: t(:already_logged_in, scope: :authentication)
              end
            end
          end
        end

        private

          def redirect_to_return_to_or_to(url, **kwargs)
            if return_to = params[:return_to].presence || session.delete(:return_to).presence
              unless return_to.start_with?("/")
                unless allowed_host?(return_to)
                  ReportError.call "Invalid return_to: #{return_to}"
                end
                kwargs[:allow_other_host] = true
              end

              url = return_to
            end

            # Don't use `html_redirect_to` here, because another format might be requested, e.g. ICS.
            redirect_to \
              url,
              **kwargs
          end

          def auth_user_scope
            @auth_user_scope ||=
              self
                .class
                .auth_user_scope
                .then { eval _1 }
          end

          def cookie_name = :remember_token

          def require_authentication
            request_authentication unless authenticated?
          end

          def resume_session
            return ::Current.user if ::Current.user

            cookies
              .signed[cookie_name]
              &.then {
                auth_user_scope.find_by(remember_token: _1)
              }&.then {
                set_current_user(_1)
              }
          end

          def request_authentication
            session[:return_to] = request.url
            redirect_to [::Current.namespace, :login],
              alert: t(:cta, scope: :authentication)
          end

          def authenticate_and_redirect(user)
            authenticate(user)

            redirect_to_return_to_or_to \
              after_authentication_url,
              notice: t(:success, scope: :authentication)
          end

          def after_authentication_url = [::Current.namespace, :root]

          def authenticate(user)
            unless auth_user_scope.exists?(id: user)
              raise "Unexpected user: #{user}"
            end

            set_current_user(user)
          end

          def unauthenticate
            ::Current.user.reset_remember_token!
            set_current_user(nil)
          end

          def set_current_user(user)
            if ::Current.user = user
              %i[id email name].index_with {
                user&.public_send _1
              }.then {
                Sentry.set_user(**_1)
              }

              cookies.signed.permanent[cookie_name] = {
                value:     user.remember_token,
                httponly:  true,
                secure:    true,
                same_site: :lax,
                domain:    :all
              }
            else
              Sentry.set_user({})
              cookies.delete(cookie_name, domain: :all)
            end

            ::Current.user
          end
      end
    end

    def self.included(base)
      base.include self[]
    end
  end
end
