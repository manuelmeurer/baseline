# frozen_string_literal: true

module Baseline
  module Authentication
    def self.[](user_class_name)
      @auth_user_class_name = user_class_name

      Module.new do
        extend ActiveSupport::Concern

        included do
          before_action do
            next unless user = params[:t]&.then { auth_user_class.find_signed(_1) }

            authenticate user
            redirect_to params.permit!.except(:t)
          end

          before_action :require_authentication

          helper_method def authenticated?   = !!resume_session
          helper_method def unauthenticated? = !authenticated?
        end

        class_methods do
          def allow_unauthenticated_access(**)
            # If the `require_authentication` callback has not been defined, an ArgumentError is raised.
            skip_before_action(:require_authentication, **)
          rescue ArgumentError
          else
            before_action(:resume_session, **) # Set Current.user
          end
        end

        private

          def auth_user_class            = @auth_user_class ||= @auth_user_class_name.constantize
          def auth_user_class_identifier = @auth_user_class_name.underscore

          def require_authentication
            request_authentication unless authenticated?
          end

          def resume_session
            ::Current.public_send "#{auth_user_class_identifier}=",
              ::Current.public_send(auth_user_class_identifier) ||
                cookies
                  .signed[:"#{auth_user_class_identifier}_id"]
                  &.then {
                    auth_user_class.find_by(id: _1)
                  }
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

          def authenticate
            unless user.is_a?(auth_user_class)
              raise "Unexpected user class: #{user.class}"
            end

            ::Current.public_send "#{auth_user_class_identifier}=", user
            cookies.signed.permanent[:"#{auth_user_class_identifier}_id"] = {
              value:     user.id,
              httponly:  true,
              same_site: :lax
            }
          end

          def unauthenticate
            unless user.is_a?(auth_user_class)
              raise "Unexpected user class: #{user.class}"
            end

            ::Current.public_send "#{auth_user_class_identifier}=", nil
            cookies.delete :"#{auth_user_class_identifier}_id"
          end
      end
    end

    def self.included(base)
      base.include self["User"]
    end
  end
end
