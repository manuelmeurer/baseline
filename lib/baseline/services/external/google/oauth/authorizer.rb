# frozen_string_literal: true

module Baseline
  module External
    module Google
      module Oauth
        class Authorizer < ApplicationService
          def initialize(admin_user)
            @user_authorizer = Helpers.initialize_user_authorizer(admin_user)
            super()
          end

          def auth_url(login_hint)
            @user_authorizer.get_authorization_url \
              login_hint:
          end

          def auth_credentials(code)
            @user_authorizer.get_credentials_from_code \
              user_id:  "default",
              code:
          end

          def scopes
            @user_authorizer.instance_variable_get("@scope")
          end
        end
      end
    end
  end
end
