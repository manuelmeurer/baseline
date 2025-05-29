# frozen_string_literal: true

module Baseline
  module Authentication
    def self.[](user_class)
      underscored_user_class = user_class.to_s.underscore

      Module.new do
        extend ActiveSupport::Concern

        included do
          before_action do
            next unless user = params[:t]&.then { user_class.find_signed(_1) }

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

          def require_authentication
            request_authentication unless authenticated?
          end

          # Use define_method, since we're accessing the user_class variable.
          define_method :resume_session do
            ::Current.public_send "#{underscored_user_class}=",
              ::Current.public_send(underscored_user_class) ||
                cookies
                  .signed[:"#{underscored_user_class}_id"]
                  &.then {
                    user_class.find_by(id: _1)
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

          # Use define_method, since we're accessing the user_class variable.
          define_method :authenticate do |user|
            unless user.is_a?(user_class)
              raise "Unexpected user class: #{user.class}"
            end

            ::Current.public_send "#{underscored_user_class}=", user
            cookies.signed.permanent[:"#{underscored_user_class}_id"] = {
              value:     user.id,
              httponly:  true,
              same_site: :lax
            }
          end

          # Use define_method, since we're accessing the user_class variable.
          define_method :unauthenticate do |user|
            unless user.is_a?(user_class)
              raise "Unexpected user class: #{user.class}"
            end

            ::Current.public_send "#{underscored_user_class}=", nil
            cookies.delete :"#{underscored_user_class}_id"
          end
      end
    end

    def self.included(base)
      base.include self[User]
    end
  end
end
